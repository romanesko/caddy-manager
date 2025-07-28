# Release Guide

This document explains how to create releases for Caddy Manager.

## Automatic Releases

The project uses GitHub Actions to automatically build and release binaries when you push a tag.

### Creating a Release

1. **Update version** (if needed):
   ```bash
   # Update version in go.mod if needed
   # The version is typically managed through git tags
   ```

2. **Create and push a tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **GitHub Actions will automatically**:
   - Build for all supported platforms
   - Create release packages (tar.gz and zip)
   - Create a GitHub release with all binaries
   - Generate release notes

### Supported Platforms

- **Linux AMD64** - `caddy-manager-linux-amd64`
- **Linux ARM64** - `caddy-manager-linux-arm64`
- **macOS AMD64** - `caddy-manager-darwin-amd64`
- **macOS ARM64** - `caddy-manager-darwin-arm64`


## Manual Builds

You can also build manually using Makefile commands:

```bash
# Build for current platform
make build

# Build for specific platform
make build-linux-amd64
make build-darwin-amd64
make build-darwin-arm64


# Build for all platforms
make build-all

# Create release packages
make release-packages
```

## Release Package Contents

Each release package contains:
- `caddy-manager` - The executable
- `README.md` - Documentation
- `env.example` - Environment configuration example
- `SUDO_SETUP.md` - Sudo setup instructions

## Installation from Release

1. **Download** the appropriate package for your platform
2. **Extract** the archive
3. **Make executable** (Linux/macOS):
   ```bash
   chmod +x caddy-manager
   ```
4. **Configure** environment:
   ```bash
   cp env.example .env
   # Edit .env with your settings
   ```
5. **Setup sudo** (if needed):
   ```bash
   sudo ./caddy-manager setup-sudo
   ```
6. **Run**:
   ```bash
   ./caddy-manager
   ```

## Versioning

We use [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- Example: `v1.0.0`, `v1.1.0`, `v1.0.1`

## Release Checklist

Before creating a release:

- [ ] All tests pass
- [ ] Documentation is up to date
- [ ] No sensitive data in the code
- [ ] Version is appropriate
- [ ] Changelog is updated (if applicable)

## Troubleshooting

### Build Issues

If builds fail:
1. Check GitHub Actions logs
2. Ensure all dependencies are properly specified in `go.mod`
3. Verify the Go version is compatible

### Release Issues

If releases don't appear:
1. Check that the tag was pushed correctly
2. Verify GitHub Actions completed successfully
3. Check repository permissions for the GitHub token 