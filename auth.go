package main

import (
	"os"

	"github.com/gin-gonic/gin"
)

// BasicAuthMiddleware creates middleware for Basic Authentication
func BasicAuthMiddleware() gin.HandlerFunc {
	username := os.Getenv("AUTH_USERNAME")
	password := os.Getenv("AUTH_PASSWORD")

	// If credentials are not configured, skip authentication
	if username == "" || password == "" {
		return func(c *gin.Context) {
			c.Next()
		}
	}

	return gin.BasicAuth(gin.Accounts{
		username: password,
	})
}

// SecureHeadersMiddleware adds security headers
func SecureHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Next()
	}
}
