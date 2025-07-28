package main

import (
	"embed"
	"io/fs"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

//go:embed static/*
var staticFS embed.FS

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using default values")
	}

	// Get port from environment variables
	port := os.Getenv("PORT")
	if port == "" {
		port = "8000" // Default to 8000 as requested
	}

	// Create Gin router
	r := gin.Default()

	// Add security middleware
	r.Use(SecureHeadersMiddleware())

	// Configure CORS
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Apply Basic Authentication to all routes
	r.Use(BasicAuthMiddleware())

	// Static files for frontend (embed)
	staticServer, _ := fs.Sub(staticFS, "static")
	r.StaticFS("/static", http.FS(staticServer))

	// Отдача index.html из embed
	r.GET("/", func(c *gin.Context) {
		file, err := staticFS.Open("static/index.html")
		if err != nil {
			c.String(404, "index.html not found")
			return
		}
		stat, _ := file.Stat()
		c.DataFromReader(200, stat.Size(), "text/html", file, nil)
	})

	// API routes
	api := r.Group("/api")
	{
		api.GET("/caddyfile", getCaddyfile)
		api.POST("/caddyfile", saveCaddyfile)
		api.POST("/restart", restartCaddy)
		api.GET("/backups", getBackups)
		api.POST("/backup", createBackup)
		api.GET("/backup/:id", getBackup)
		api.POST("/restore/:id", restoreBackup)
		api.GET("/check-ports", checkPorts)
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
