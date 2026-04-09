# Nginx Brotli Builder

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/urcube/nginx-brotli/docker-publish.yml?branch=main&label=build&style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/urcb/nginx-brotli?style=flat-square)
![Docker Image Version](https://img.shields.io/docker/v/urcb/nginx-brotli/latest?label=nginx&style=flat-square&logo=nginx)
![License](https://img.shields.io/github/license/urcube/nginx-brotli?style=flat-square)

Automated Build Repository for Nginx with Native Brotli Support

This repository is strictly used for automatically building the nginx-brotli Docker image. It is not intended for standalone use but serves as a high-performance base image. By compiling the Google ngx_brotli module against the official Nginx source, it provides superior compression for modern web applications while remaining lightweight and secure.

Native Brotli Compression: Includes both filter and static modules for on-the-fly and pre-compressed content.

**Guaranteed Compatibility**: Uses a dynamic build process that extracts configuration arguments from the official Nginx binary to ensure a perfect binary match.  
**Always Up-to-Date**: The build pipeline automatically tracks the official nginx:alpine upstream, rebuilding and verifying the image whenever a new version is released.  
**Minimalist Footprint**: Utilizes a multi-stage Docker build to ensure that compilers and build-dependencies are discarded, leaving only the optimized binaries.  
**Pre-Configured Loading**: The Brotli modules are automatically injected into the nginx.conf during the build process, making the image ready for immediate use.

## Usage

This project auto-builds the urcb/nginx-brotli image. You can use it as a drop-in replacement for the official Nginx image in your 

### Docker Compose

```YAML
services:
  web:
    image: urcb/nginx-brotli:latest
    ports:
      - "80:80"
```

### Enable Brotli in Nginx

```nginx
http {
    brotli on;
    brotli_comp_level 6;
    brotli_static on;
    brotli_types text/plain text/css application/javascript application/json image/svg+xml;
}
```

## How it Works

The build process uses a 2-Stage Pipeline to ensure stability and performance:

Builder: Downloads the Nginx source code matching the official image version, clones the ngx_brotli library, and compiles the dynamic modules using the original build flags.

Final: Copies the compiled .so modules into the official Nginx Alpine image and configures the system to load them automatically on startup.


## Development & Testing

This repository includes a minimal test suite to verify the build locally before pushing to Git.
Local Test Script

The test.sh script performs a full build, checks Nginx syntax, and verifies that the container returns Content-Encoding: br headers.
Bash

```bash
sudo ./test.sh
```

## Project Structure

- **Dockerfile**: The multi-stage build instructions that extract Nginx configuration for perfect module compatibility.
- **test.sh**: A minimal local script to build the image, verify Nginx syntax, and confirm Brotli compression is active.
- **.github/workflows/**: Automated pipeline that tracks official Nginx Alpine updates and runs validation tests before publishing.