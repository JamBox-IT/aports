# Repository Configuration

## Required Secrets

### Signing Keys (Required)
- **RSA_PRIVATE_KEY**: Current Alpine package signing private key
  - Format: PEM-encoded RSA private key
  - Generated with: `abuild-keygen -a -i`
  - Location: `~/.abuild/*.rsa`

- **RSA_PUBLIC_KEY**: Current Alpine package signing public key
  - Format: PEM-encoded RSA public key
  - Generated with: `abuild-keygen -a -i`
  - Location: `~/.abuild/*.rsa.pub`

### Key Rotation (Optional)
- **NEW_RSA_PRIVATE_KEY**: New private key for key rotation
  - Only set when rotating keys
  - Must be paired with NEW_RSA_PUBLIC_KEY
  - Workflow will re-sign all packages with this key

- **NEW_RSA_PUBLIC_KEY**: New public key for key rotation
  - Only set when rotating keys
  - Must be paired with NEW_RSA_PRIVATE_KEY
  - Workflow validates key pair before rotation

## Recommended Repository Variables

### Version Control
- **DEFAULT_ALPINE_VERSION**: Default Alpine version for manual workflows
  - Suggested value: `v3.19`
  - Used when version detection fails

### Build Configuration
- **ALPINE_MIRROR**: Alpine mirror URL for faster builds
  - Default: `https://dl-cdn.alpinelinux.org/alpine`
  - Regional mirrors may improve build speed

- **SUPPORTED_ARCHITECTURES**: Space-separated list of architectures
  - Default: `x86_64 aarch64 armv7 armhf`
  - Modify if you only support specific architectures

### Repository Settings
- **REPOSITORY_NAME**: Display name for the repository
  - Suggested value: `JamBox Alpine Repository`
  - Used in documentation generation

- **REPOSITORY_MAINTAINER**: Package maintainer email
  - Format: `Name <email@example.com>`
  - Used in APKBUILD templates

## Key Rotation Process

### Step 1: Generate New Keys
```bash
# On a secure machine
abuild-keygen -a -i -n

# This creates:
# ~/.abuild/yourname-xxxxxxxx.rsa
# ~/.abuild/yourname-xxxxxxxx.rsa.pub
```

### Step 2: Add New Keys to Secrets
1. Go to repository Settings → Secrets and variables → Actions
2. Add new secrets:
   - NEW_RSA_PRIVATE_KEY: Content of `~/.abuild/*.rsa`
   - NEW_RSA_PUBLIC_KEY: Content of `~/.abuild/*.rsa.pub`

### Step 3: Trigger Key Rotation
Run the sign-and-publish workflow manually:
```
Actions → Sign and Publish Alpine Repository → Run workflow
- Select alpine-version (e.g., v3.19)
- Do NOT check "force-resign" (rotation will handle it)
```

The workflow will:
1. Validate new key pair
2. Re-sign all packages with new key
3. Update APKINDEX with new signatures
4. Publish to gh-pages

### Step 4: Replace Old Keys
After successful workflow completion:
1. Update RSA_PRIVATE_KEY with value from NEW_RSA_PRIVATE_KEY
2. Update RSA_PUBLIC_KEY with value from NEW_RSA_PUBLIC_KEY
3. Delete NEW_RSA_PRIVATE_KEY secret
4. Delete NEW_RSA_PUBLIC_KEY secret

### Step 5: Distribute New Public Key
Users must update their APK keyring:
```bash
# Download new public key
wget https://jambox-it.github.io/aports/keys/jambox-newfingerprint.rsa.pub

# Install to system keyring
sudo cp jambox-newfingerprint.rsa.pub /etc/apk/keys/

# Update package cache
sudo apk update
```

## Manual Workflow Triggers

### Force Re-sign All Packages
Use when signatures are corrupted or invalid:
```
Actions → Sign and Publish Alpine Repository → Run workflow
- Select alpine-version
- Check "force-resign"
```

### Rebuild Repository Index
Use when APKINDEX is missing or corrupted:
```
Actions → Sign and Publish Alpine Repository → Run workflow
- Select alpine-version
- Leave "force-resign" unchecked
```

## Troubleshooting

### Invalid Signature Errors
If packages have invalid signatures:
1. Run sign-and-publish workflow with "force-resign" enabled
2. Workflow will detect and fix invalid signatures automatically

### Key Pair Mismatch
If private/public keys don't match:
1. Workflow will fail during validation step
2. Check that both RSA_PRIVATE_KEY and RSA_PUBLIC_KEY are from the same `abuild-keygen` run
3. Verify key format (PEM, not DER or SSH format)

### APKINDEX Missing
If APKINDEX.tar.gz is missing:
1. Run sign-and-publish workflow manually
2. Workflow will regenerate APKINDEX from existing packages
