package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

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

	// Static files for frontend
	r.Static("/static", "./static")
	r.StaticFile("/", "./static/index.html")

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
