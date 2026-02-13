#!/bin/bash
# Verify RSA keys are in correct format for abuild/GitHub Actions
#
# Usage:
#   ./scripts/verify-rsa-keys.sh [private-key-file] [public-key-file]
#
# Examples:
#   ./scripts/verify-rsa-keys.sh ~/.abuild/jambox.rsa ~/.abuild/jambox.rsa.pub
#   ./scripts/verify-rsa-keys.sh ./jambox.rsa ./jambox.rsa.pub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PRIVATE_KEY="${1:-.}"
PUBLIC_KEY="${2:-.}"
ISSUES=0

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    ISSUES=$((ISSUES + 1))
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if files exist
check_files() {
    print_header "Checking File Existence"

    if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "." ]; then
        print_fail "Private key path not specified"
        echo ""
        echo "Usage: $0 <private-key-file> <public-key-file>"
        echo ""
        echo "Examples:"
        echo "  $0 ~/.abuild/jambox.rsa ~/.abuild/jambox.rsa.pub"
        echo "  $0 ./jambox.rsa ./jambox.rsa.pub"
        exit 1
    fi

    if [ -z "$PUBLIC_KEY" ] || [ "$PUBLIC_KEY" = "." ]; then
        print_fail "Public key path not specified"
        exit 1
    fi

    if [ ! -f "$PRIVATE_KEY" ]; then
        print_fail "Private key not found: $PRIVATE_KEY"
        exit 1
    else
        print_pass "Private key exists: $PRIVATE_KEY"
    fi

    if [ ! -f "$PUBLIC_KEY" ]; then
        print_fail "Public key not found: $PUBLIC_KEY"
        exit 1
    else
        print_pass "Public key exists: $PUBLIC_KEY"
    fi

    echo ""
}

# Check file permissions
check_permissions() {
    print_header "Checking File Permissions"

    local priv_perms=$(stat -f%OLp "$PRIVATE_KEY" 2>/dev/null || stat -c%a "$PRIVATE_KEY" 2>/dev/null)
    local pub_perms=$(stat -f%OLp "$PUBLIC_KEY" 2>/dev/null || stat -c%a "$PUBLIC_KEY" 2>/dev/null)

    if [ "$priv_perms" = "600" ] || [ "$priv_perms" = "0600" ]; then
        print_pass "Private key permissions: 600 (correct)"
    else
        print_warn "Private key permissions: $priv_perms (should be 600)"
        print_info "Fix with: chmod 600 $PRIVATE_KEY"
    fi

    if [ "$pub_perms" = "644" ] || [ "$pub_perms" = "0644" ]; then
        print_pass "Public key permissions: 644 (correct)"
    else
        print_warn "Public key permissions: $pub_perms (should be 644)"
        print_info "Fix with: chmod 644 $PUBLIC_KEY"
    fi

    echo ""
}

# Check private key format
check_private_key_format() {
    print_header "Checking Private Key Format"

    local first_line=$(head -1 "$PRIVATE_KEY")

    case "$first_line" in
        "-----BEGIN RSA PRIVATE KEY-----")
            print_pass "Format: PKCS#1 RSA (Correct for abuild)"
            return 0
            ;;
        "-----BEGIN ENCRYPTED PRIVATE KEY-----")
            print_fail "Format: PKCS#8 Encrypted (Wrong - Not compatible with abuild)"
            print_warn "This is the format causing your OpenSSL errors"
            ISSUES=$((ISSUES + 1))
            return 1
            ;;
        "-----BEGIN PRIVATE KEY-----")
            print_fail "Format: PKCS#8 (Wrong - Not compatible with abuild)"
            print_warn "Modern OpenSSL default, but abuild needs PKCS#1"
            ISSUES=$((ISSUES + 1))
            return 1
            ;;
        "-----BEGIN EC PRIVATE KEY-----")
            print_fail "Format: EC Key (Wrong - abuild needs RSA)"
            print_warn "This is an Elliptic Curve key, not RSA"
            ISSUES=$((ISSUES + 1))
            return 1
            ;;
        *)
            print_fail "Format: Unknown - '$first_line'"
            print_warn "Should start with '-----BEGIN RSA PRIVATE KEY-----'"
            ISSUES=$((ISSUES + 1))
            return 1
            ;;
    esac

    echo ""
}

# Check public key format
check_public_key_format() {
    print_header "Checking Public Key Format"

    local first_line=$(head -1 "$PUBLIC_KEY")

    case "$first_line" in
        "-----BEGIN RSA PUBLIC KEY-----")
            print_pass "Format: PKCS#1 RSA Public (Correct)"
            ;;
        "-----BEGIN PUBLIC KEY-----")
            print_pass "Format: PKCS#8 Public (Compatible)"
            ;;
        *)
            print_warn "Format: Unexpected - '$first_line'"
            ;;
    esac

    echo ""
}

# Check key sizes
check_key_sizes() {
    print_header "Checking Key Sizes"

    local priv_size=$(wc -l < "$PRIVATE_KEY")
    local pub_size=$(wc -l < "$PUBLIC_KEY")

    print_info "Private key: $priv_size lines"
    print_info "Public key: $pub_size lines"

    if [ "$priv_size" -lt 20 ]; then
        print_fail "Private key too small ($priv_size lines)"
        ISSUES=$((ISSUES + 1))
    elif [ "$priv_size" -gt 100 ]; then
        print_warn "Private key unusually large ($priv_size lines)"
    else
        print_pass "Private key size reasonable ($priv_size lines)"
    fi

    if [ "$pub_size" -lt 2 ]; then
        print_fail "Public key too small ($pub_size lines)"
        ISSUES=$((ISSUES + 1))
    elif [ "$pub_size" -gt 20 ]; then
        print_warn "Public key unusually large ($pub_size lines)"
    else
        print_pass "Public key size reasonable ($pub_size lines)"
    fi

    echo ""
}

# Check key content
check_key_content() {
    print_header "Checking Key Content"

    # Check for BEGIN/END markers
    if ! grep -q "-----END RSA PRIVATE KEY-----" "$PRIVATE_KEY"; then
        print_fail "Private key missing END marker"
        ISSUES=$((ISSUES + 1))
    else
        print_pass "Private key has proper END marker"
    fi

    if ! tail -1 "$PUBLIC_KEY" | grep -q "-----END.*PUBLIC KEY-----"; then
        print_fail "Public key missing END marker"
        ISSUES=$((ISSUES + 1))
    else
        print_pass "Public key has proper END marker"
    fi

    # Try to extract key modulus (if OpenSSL available)
    if command -v openssl &> /dev/null; then
        print_header "Validating with OpenSSL"

        # Check private key validity
        if openssl rsa -in "$PRIVATE_KEY" -check -noout &>/dev/null; then
            print_pass "Private key is valid RSA key"
        else
            print_fail "Private key validation failed"
            print_info "Trying to identify issue..."
            openssl rsa -in "$PRIVATE_KEY" -check -noout 2>&1 | grep -v "^RSA key ok$" || true
            ISSUES=$((ISSUES + 1))
        fi

        # Check public key validity
        if openssl rsa -pubin -in "$PUBLIC_KEY" -check -noout &>/dev/null; then
            print_pass "Public key is valid RSA public key"
        else
            # Try alternate format
            if openssl pkey -pubin -in "$PUBLIC_KEY" -check -noout &>/dev/null; then
                print_pass "Public key is valid (PKCS#8 format)"
            else
                print_fail "Public key validation failed"
                ISSUES=$((ISSUES + 1))
            fi
        fi

        # Extract and compare key fingerprints
        print_header "Verifying Key Pair Match"

        PRIV_MOD=$(openssl rsa -in "$PRIVATE_KEY" -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1)
        PUB_MOD=$(openssl rsa -pubin -in "$PUBLIC_KEY" -noout -modulus 2>/dev/null || openssl pkey -pubin -in "$PUBLIC_KEY" -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1)

        if [ "$PRIV_MOD" = "$PUB_MOD" ]; then
            print_pass "Private and public keys match"
        else
            print_fail "Private and public keys don't match (from different pairs)"
            ISSUES=$((ISSUES + 1))
        fi
    else
        print_warn "OpenSSL not installed - skipping detailed validation"
        print_info "To install: brew install openssl (macOS) or apt-get install openssl (Linux)"
    fi

    echo ""
}

# Test with abuild if available
test_with_abuild() {
    if ! command -v abuild &> /dev/null; then
        print_warn "abuild not installed - skipping runtime test"
        print_info "To install: apk add abuild (Alpine) or via Docker"
        return
    fi

    print_header "Testing with abuild"

    # Create temporary abuild config
    local temp_config=$(mktemp)
    cat > "$temp_config" << EOF
PACKAGER_PRIVKEY=$PRIVATE_KEY
PACKAGER="Test User <test@example.com>"
EOF

    # Try to use the key
    if openssl rsa -in "$PRIVATE_KEY" -noout &>/dev/null; then
        print_pass "Key readable by abuild/OpenSSL"
    else
        print_fail "Key not readable by abuild/OpenSSL"
        ISSUES=$((ISSUES + 1))
    fi

    rm -f "$temp_config"

    echo ""
}

# Provide remediation advice
provide_remediation() {
    if [ $ISSUES -eq 0 ]; then
        print_header "Summary: All Checks Passed!"
        echo -e "${GREEN}Your RSA keys are properly formatted and ready to use with GitHub Actions.${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Add to GitHub Secrets:"
        echo "   - Name: RSA_PRIVATE_KEY"
        echo "   - Value: (contents of $PRIVATE_KEY)"
        echo ""
        echo "   - Name: RSA_PUBLIC_KEY"
        echo "   - Value: (contents of $PUBLIC_KEY)"
        echo ""
        echo "2. Deploy workflow: .github/workflows/build-and-release.yml"
        echo ""
        echo "3. Push to main branch to trigger build"
        return 0
    fi

    print_header "Summary: Issues Found ($ISSUES)"
    echo -e "${RED}Your RSA keys have issues that will prevent them from working.${NC}"
    echo ""

    if grep -q "ENCRYPTED PRIVATE KEY" "$PRIVATE_KEY"; then
        echo -e "${YELLOW}PRIMARY ISSUE: Private key is PKCS#8 encrypted format${NC}"
        echo ""
        echo "This is the cause of your OpenSSL errors:"
        echo "  error:1608010C:STORE routines:ossl_store_handle_load_result:unsupported"
        echo "  Input structure: EncryptedPrivateKeyInfo"
        echo ""
        echo "SOLUTION: Regenerate keys using Alpine's abuild-keygen:"
        echo ""
        echo "  docker run --rm -v \$(pwd):/work alpine:latest sh -c '"
        echo "    apk add --no-cache abuild"
        echo "    cd /root && abuild-keygen -n -a"
        echo "    cp .abuild/*.rsa* /work/"
        echo "  '"
        echo ""
        echo "Or use the helper script:"
        echo "  bash scripts/generate-abuild-keys.sh jambox"
        echo ""
    fi

    if grep -q "^-----BEGIN PRIVATE KEY-----" "$PRIVATE_KEY"; then
        echo -e "${YELLOW}PRIMARY ISSUE: Private key is PKCS#8 format (unencrypted)${NC}"
        echo ""
        echo "Modern OpenSSL generates this by default, but abuild needs PKCS#1."
        echo ""
        echo "SOLUTION: Convert to PKCS#1 format:"
        echo ""
        echo "  openssl rsa -in jambox.pem -out jambox.rsa"
        echo ""
        echo "Or regenerate with abuild-keygen (recommended):"
        echo "  bash scripts/generate-abuild-keys.sh jambox"
        echo ""
    fi

    echo "For detailed information, see: RSA_KEY_SETUP.md"
    echo ""
    return 1
}

# Main execution
main() {
    echo ""
    print_header "RSA Key Verification Tool"
    echo "Validating keys for use with Alpine abuild and GitHub Actions"
    echo ""

    check_files
    check_permissions
    check_private_key_format || true
    check_public_key_format
    check_key_sizes
    check_key_content
    test_with_abuild

    provide_remediation
    return $?
}

main "$@"
