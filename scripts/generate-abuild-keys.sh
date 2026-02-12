#!/bin/bash
# Generate Alpine Linux abuild RSA keys compatible with GitHub Actions
#
# Usage:
#   ./scripts/generate-abuild-keys.sh [keyname] [output-dir]
#
# Examples:
#   ./scripts/generate-abuild-keys.sh jambox ./keys
#   ./scripts/generate-abuild-keys.sh (uses default: "builder" and current dir)
#
# This script uses Docker to ensure consistent key generation across platforms

set -e

# Configuration
KEY_NAME="${1:-builder}"
OUTPUT_DIR="${2:-.}"
USE_DOCKER="${USE_DOCKER:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if output directory exists or can be created
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR" || print_error "Cannot create output directory: $OUTPUT_DIR"
        print_success "Created output directory: $OUTPUT_DIR"
    else
        print_success "Output directory exists: $OUTPUT_DIR"
    fi

    # Check Docker availability
    if [ "$USE_DOCKER" = "true" ]; then
        if ! command -v docker &> /dev/null; then
            print_warning "Docker not found, will attempt local generation"
            USE_DOCKER=false
        else
            print_success "Docker is available"
        fi
    fi

    # Check Alpine availability if not using Docker
    if [ "$USE_DOCKER" = "false" ]; then
        if ! command -v abuild &> /dev/null; then
            print_error "Neither Docker nor abuild found. Install one of:"
            echo "  - Docker: https://www.docker.com/"
            echo "  - Alpine Linux with abuild"
        else
            print_success "abuild is available"
        fi
    fi

    echo ""
}

# Generate keys using Docker
generate_with_docker() {
    print_header "Generating Keys with Docker"

    echo "Key name: $KEY_NAME"
    echo "Output directory: $OUTPUT_DIR"
    echo ""

    # Run Alpine in Docker and generate keys
    docker run --rm \
        -v "$(cd "$OUTPUT_DIR" && pwd):/work" \
        alpine:latest \
        sh -c "
            apk add --no-cache abuild openssl

            # Create temporary directory for key generation
            mkdir -p /tmp/keygen
            cd /tmp/keygen

            # Generate keys using abuild-keygen
            # -n: Non-interactive
            # -a: Install keys automatically (we'll copy them out)
            abuild-keygen -n -a -q > /dev/null 2>&1 || true

            # Copy generated keys to output
            if [ -f /root/.abuild/$KEY_NAME.rsa ]; then
                cp /root/.abuild/$KEY_NAME.rsa /work/$KEY_NAME.rsa
                chmod 600 /work/$KEY_NAME.rsa
                echo 'Private key generated'
            else
                # Try to find any .rsa file
                FIRST_KEY=\$(find /root/.abuild -name '*.rsa' -type f | head -1)
                if [ -n \"\$FIRST_KEY\" ]; then
                    cp \"\$FIRST_KEY\" /work/$KEY_NAME.rsa
                    chmod 600 /work/$KEY_NAME.rsa
                    echo 'Private key generated (from auto-named key)'
                else
                    echo 'Failed to generate private key'
                    exit 1
                fi
            fi

            if [ -f /root/.abuild/$KEY_NAME.rsa.pub ]; then
                cp /root/.abuild/$KEY_NAME.rsa.pub /work/$KEY_NAME.rsa.pub
                chmod 644 /work/$KEY_NAME.rsa.pub
                echo 'Public key generated'
            else
                # Try to find any .rsa.pub file
                FIRST_PUB=\$(find /root/.abuild -name '*.rsa.pub' -type f | head -1)
                if [ -n \"\$FIRST_PUB\" ]; then
                    cp \"\$FIRST_PUB\" /work/$KEY_NAME.rsa.pub
                    chmod 644 /work/$KEY_NAME.rsa.pub
                    echo 'Public key generated (from auto-named key)'
                else
                    echo 'Failed to generate public key'
                    exit 1
                fi
            fi
        " || print_error "Docker key generation failed"

    print_success "Keys generated successfully with Docker"
}

# Generate keys locally with abuild
generate_locally() {
    print_header "Generating Keys with Local abuild"

    echo "Key name: $KEY_NAME"
    echo "Output directory: $OUTPUT_DIR"
    echo ""

    # Generate keys in temporary location
    TEMP_HOME=$(mktemp -d)
    export HOME="$TEMP_HOME"

    # Generate keys
    abuild-keygen -n -a -q > /dev/null 2>&1 || true

    # Copy keys to output
    if [ -f "$HOME/.abuild/$KEY_NAME.rsa" ]; then
        cp "$HOME/.abuild/$KEY_NAME.rsa" "$OUTPUT_DIR/$KEY_NAME.rsa"
        chmod 600 "$OUTPUT_DIR/$KEY_NAME.rsa"
        print_success "Private key generated"
    else
        print_error "Failed to generate private key with abuild"
    fi

    if [ -f "$HOME/.abuild/$KEY_NAME.rsa.pub" ]; then
        cp "$HOME/.abuild/$KEY_NAME.rsa.pub" "$OUTPUT_DIR/$KEY_NAME.rsa.pub"
        chmod 644 "$OUTPUT_DIR/$KEY_NAME.rsa.pub"
        print_success "Public key generated"
    else
        print_error "Failed to generate public key with abuild"
    fi

    # Cleanup
    rm -rf "$TEMP_HOME"
}

# Verify key format
verify_keys() {
    print_header "Verifying Key Format"

    local private_key="$OUTPUT_DIR/$KEY_NAME.rsa"
    local public_key="$OUTPUT_DIR/$KEY_NAME.rsa.pub"

    # Check private key exists and is readable
    if [ ! -f "$private_key" ]; then
        print_error "Private key not found: $private_key"
    fi
    print_success "Private key exists"

    # Check public key exists and is readable
    if [ ! -f "$public_key" ]; then
        print_error "Public key not found: $public_key"
    fi
    print_success "Public key exists"

    # Verify key format (should be PKCS#1, not PKCS#8)
    local key_header=$(head -1 "$private_key")
    if [[ "$key_header" == "-----BEGIN RSA PRIVATE KEY-----" ]]; then
        print_success "Private key format: PKCS#1 RSA (Correct)"
    elif [[ "$key_header" == "-----BEGIN ENCRYPTED PRIVATE KEY-----" ]]; then
        print_error "Private key is PKCS#8 encrypted format (Incompatible with abuild)"
    elif [[ "$key_header" == "-----BEGIN PRIVATE KEY-----" ]]; then
        print_error "Private key is PKCS#8 format (Incompatible with abuild)"
    else
        print_warning "Unknown key format: $key_header"
    fi

    # Check key sizes
    local priv_lines=$(wc -l < "$private_key")
    local pub_lines=$(wc -l < "$public_key")

    if [ "$priv_lines" -lt 10 ]; then
        print_error "Private key seems too small: $priv_lines lines"
    fi
    print_success "Private key size looks reasonable: $priv_lines lines"

    if [ "$pub_lines" -lt 2 ]; then
        print_error "Public key seems too small: $pub_lines lines"
    fi
    print_success "Public key size looks reasonable: $pub_lines lines"

    echo ""
}

# Display key contents for GitHub Secrets
display_keys() {
    print_header "Keys Generated Successfully!"

    local private_key="$OUTPUT_DIR/$KEY_NAME.rsa"
    local public_key="$OUTPUT_DIR/$KEY_NAME.rsa.pub"

    echo ""
    echo "Files created:"
    ls -lh "$private_key" "$public_key"
    echo ""

    echo -e "${YELLOW}To add these keys to GitHub Secrets:${NC}"
    echo ""
    echo "1. Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
    echo ""
    echo "2. Create secret: RSA_PRIVATE_KEY"
    echo "   Value (copy from below):"
    echo -e "${BLUE}---BEGIN PRIVATE KEY---${NC}"
    cat "$private_key"
    echo -e "${BLUE}---END PRIVATE KEY---${NC}"
    echo ""
    echo "3. Create secret: RSA_PUBLIC_KEY"
    echo "   Value (copy from below):"
    echo -e "${BLUE}---BEGIN PUBLIC KEY---${NC}"
    cat "$public_key"
    echo -e "${BLUE}---END PUBLIC KEY---${NC}"
    echo ""

    # Offer to copy to clipboard on macOS
    if command -v pbcopy &> /dev/null; then
        echo -e "${YELLOW}macOS tip:${NC} Copy private key to clipboard:"
        echo "  cat $private_key | pbcopy"
        echo ""
    fi
}

# Main execution
main() {
    print_header "Alpine Linux abuild Key Generator"
    echo "Generating RSA keys for GitHub Actions CI/CD"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Generate keys
    if [ "$USE_DOCKER" = "true" ]; then
        generate_with_docker
    else
        generate_locally
    fi

    # Verify keys
    verify_keys

    # Display keys for setup
    display_keys

    print_success "Ready to use with GitHub Actions!"
}

# Run main function
main "$@"
