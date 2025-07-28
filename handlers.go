package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// CaddyfileContent represents the content of Caddyfile
type CaddyfileContent struct {
	Content string `json:"content"`
}

// BackupInfo represents backup information
type BackupInfo struct {
	ID      string    `json:"id"`
	Time    time.Time `json:"time"`
	Size    int64     `json:"size"`
	Content string    `json:"content,omitempty"`
}

// getCaddyfile returns the content of Caddyfile
func getCaddyfile(c *gin.Context) {
	caddyfilePath := getCaddyfilePath()

	// Read file with sudo
	cmd := exec.Command("sudo", "cat", caddyfilePath)
	content, err := cmd.Output()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to read Caddyfile: %v", err)})
		return
	}

	c.JSON(http.StatusOK, CaddyfileContent{Content: string(content)})
}

// saveCaddyfile saves the content of Caddyfile
func saveCaddyfile(c *gin.Context) {
	var req CaddyfileContent
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate content length to prevent DoS
	if len(req.Content) > 1024*1024 { // 1MB limit
		c.JSON(http.StatusBadRequest, gin.H{"error": "Caddyfile content too large (max 1MB)"})
		return
	}

	caddyfilePath := getCaddyfilePath()

	// Create backup before saving
	if err := createBackupFile(caddyfilePath); err != nil {
		log.Printf("Warning: Failed to create backup: %v", err)
	}

	// Save new content with sudo
	tempFile := "/tmp/caddyfile_temp"
	if err := os.WriteFile(tempFile, []byte(req.Content), 0600); err != nil { // More restrictive permissions
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create temp file: %v", err)})
		return
	}

	// Copy file with sudo
	cmd := exec.Command("sudo", "cp", tempFile, caddyfilePath)
	if err := cmd.Run(); err != nil {
		// Clean up temp file
		os.Remove(tempFile)
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to save Caddyfile: %v", err)})
		return
	}

	// Clean up temp file
	os.Remove(tempFile)

	c.JSON(http.StatusOK, gin.H{"message": "Caddyfile saved successfully"})
}

// restartCaddy restarts the Caddy server
func restartCaddy(c *gin.Context) {
	// Validate Caddyfile syntax before restart
	if err := validateCaddyfile(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid Caddyfile: %v", err)})
		return
	}

	// Restart Caddy with sudo
	cmd := exec.Command("sudo", "systemctl", "reload", "caddy")
	if err := cmd.Run(); err != nil {
		// Try alternative method with sudo
		cmd = exec.Command("sudo", "caddy", "reload", "--config", getCaddyfilePath())
		if err := cmd.Run(); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to restart Caddy: %v", err)})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Caddy restarted successfully"})
}

// getBackups returns the list of backups
func getBackups(c *gin.Context) {
	backupDir := getBackupDir()

	files, err := os.ReadDir(backupDir)
	if err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusOK, []BackupInfo{})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to read backup directory: %v", err)})
		return
	}

	var backups []BackupInfo
	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".backup") {
			info, err := file.Info()
			if err != nil {
				continue
			}

			backups = append(backups, BackupInfo{
				ID:   strings.TrimSuffix(file.Name(), ".backup"),
				Time: info.ModTime(),
				Size: info.Size(),
			})
		}
	}

	// Sort by time (newest first)
	sort.Slice(backups, func(i, j int) bool {
		return backups[i].Time.After(backups[j].Time)
	})

	c.JSON(http.StatusOK, backups)
}

// createBackup creates a new backup
func createBackup(c *gin.Context) {
	caddyfilePath := getCaddyfilePath()

	if err := createBackupFile(caddyfilePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create backup: %v", err)})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Backup created successfully"})
}

// getBackup returns the content of a specific backup
func getBackup(c *gin.Context) {
	backupID := c.Param("id")
	backupPath := filepath.Join(getBackupDir(), backupID+".backup")

	content, err := os.ReadFile(backupPath)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Backup not found"})
		return
	}

	c.JSON(http.StatusOK, CaddyfileContent{Content: string(content)})
}

// restoreBackup restores a backup
func restoreBackup(c *gin.Context) {
	backupID := c.Param("id")
	backupPath := filepath.Join(getBackupDir(), backupID+".backup")
	caddyfilePath := getCaddyfilePath()

	// Read backup
	content, err := os.ReadFile(backupPath)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Backup not found"})
		return
	}

	// Create backup of current state
	if err := createBackupFile(caddyfilePath); err != nil {
		log.Printf("Warning: Failed to create backup before restore: %v", err)
	}

	// Restore from backup
	if err := os.WriteFile(caddyfilePath, content, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to restore backup: %v", err)})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Backup restored successfully"})
}

// Helper functions

func getCaddyfilePath() string {
	path := os.Getenv("CADDYFILE_PATH")
	if path == "" {
		path = "/etc/caddy/Caddyfile"
	}
	return path
}

func getBackupDir() string {
	dir := os.Getenv("BACKUP_DIR")
	if dir == "" {
		dir = "./backups"
	}

	// Create directory if it doesn't exist
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Printf("Warning: Failed to create backup directory: %v", err)
	}

	return dir
}

func createBackupFile(caddyfilePath string) error {
	// Read file with sudo
	cmd := exec.Command("sudo", "cat", caddyfilePath)
	content, err := cmd.Output()
	if err != nil {
		return err
	}

	backupDir := getBackupDir()
	timestamp := time.Now().Format("20060102_150405")
	backupPath := filepath.Join(backupDir, timestamp+".backup")

	return os.WriteFile(backupPath, content, 0644)
}

// PortStatus represents port status
type PortStatus struct {
	Port   string `json:"port"`
	Status string `json:"status"` // "alive", "dead", "checking"
}

// checkPorts checks availability of all ports in Caddyfile
func checkPorts(c *gin.Context) {
	caddyfilePath := getCaddyfilePath()

	// Read file with sudo
	cmd := exec.Command("sudo", "cat", caddyfilePath)
	content, err := cmd.Output()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to read Caddyfile: %v", err)})
		return
	}

	// Extract all ports from Caddyfile
	ports := extractPortsFromCaddyfile(string(content))

	// Check each port
	var results []PortStatus
	for _, port := range ports {
		status := checkPortAvailability(port)
		results = append(results, PortStatus{
			Port:   port,
			Status: status,
		})
	}

	c.JSON(http.StatusOK, results)
}

// extractPortsFromCaddyfile извлекает все порты из содержимого Caddyfile
func extractPortsFromCaddyfile(content string) []string {
	var ports []string
	lines := strings.Split(content, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.Contains(line, "reverse_proxy") && !strings.Contains(line, "transport") {
			// Ищем порты в формате 127.0.0.1:PORT или localhost:PORT
			portMatches := regexp.MustCompile(`(?:127\.0\.0\.1|localhost):(\d+)`).FindStringSubmatch(line)
			if len(portMatches) > 1 {
				port := portMatches[1]
				// Проверяем, что порт еще не добавлен
				found := false
				for _, existingPort := range ports {
					if existingPort == port {
						found = true
						break
					}
				}
				if !found {
					ports = append(ports, port)
				}
			}
		}
	}

	return ports
}

// checkPortAvailability проверяет доступность порта
func checkPortAvailability(port string) string {
	timeout := time.Second * 2
	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+port, timeout)
	if err != nil {
		return "dead"
	}
	defer conn.Close()
	return "alive"
}

func validateCaddyfile() error {
	caddyfilePath := getCaddyfilePath()

	// Проверяем синтаксис с помощью sudo caddy validate
	cmd := exec.Command("sudo", "caddy", "validate", "--config", caddyfilePath)
	return cmd.Run()
}
