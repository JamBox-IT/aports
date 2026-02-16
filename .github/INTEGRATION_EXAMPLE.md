# Integration Example

## Calling from build-and-release.yml

Replace the old `publish-repository` job with:

```yaml
  sign-and-publish:
    name: Sign and Publish Alpine Repository
    needs: [detect-changes, filter-existing, build]
    if: needs.filter-existing.outputs.has-new == 'true' && !cancelled()
    uses: ./.github/workflows/sign-and-publish.yml
    permissions:
      contents: write
      pages: write
    secrets: inherit
    with:
      alpine-version: ${{ github.ref == 'refs/heads/main' && 'edge' || github.ref_name }}
```

## Required Secrets

Set these in: Repository Settings → Secrets and variables → Actions → Secrets

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| RSA_PRIVATE_KEY | Current signing private key | `abuild-keygen -a -i` → copy `~/.abuild/*.rsa` |
| RSA_PUBLIC_KEY | Current signing public key | `abuild-keygen -a -i` → copy `~/.abuild/*.rsa.pub` |
| NEW_RSA_PRIVATE_KEY | (Optional) New key for rotation | Same as above, only set during rotation |
| NEW_RSA_PUBLIC_KEY | (Optional) New key for rotation | Same as above, only set during rotation |

## Recommended Variables

Set these in: Repository Settings → Secrets and variables → Actions → Variables

| Variable Name | Suggested Value | Purpose |
|---------------|-----------------|---------|
| DEFAULT_ALPINE_VERSION | v3.19 | Fallback Alpine version |
| SUPPORTED_ARCHITECTURES | x86_64 aarch64 armv7 armhf | Limit build architectures |
| ALPINE_MIRROR | https://dl-cdn.alpinelinux.org/alpine | Custom mirror for faster builds |
| REPOSITORY_MAINTAINER | Your Name <email@example.com> | Package maintainer info |

## Manual Workflow Execution

### Rebuild repository for specific Alpine version:
```bash
Actions → Sign and Publish Alpine Repository → Run workflow
  alpine-version: v3.19
  force-resign: false
```

### Force re-sign all packages:
```bash
Actions → Sign and Publish Alpine Repository → Run workflow
  alpine-version: v3.19
  force-resign: true
```

### Test on v3.19 branch (has bad signatures):
```bash
# 1. Checkout v3.19 branch locally
git checkout v3.19

# 2. Push to trigger build
git push origin v3.19

# 3. Watch workflow detect and fix bad signatures
# Workflow will automatically:
# - Validate each package signature
# - Re-sign packages with invalid/missing signatures
# - Generate APKINDEX with verified packages
# - Publish to gh-pages
```

## Key Rotation Example

### Complete key rotation in 5 steps:

```bash
# 1. Generate new keys locally
abuild-keygen -a -i -n

# 2. Add secrets to GitHub
#    NEW_RSA_PRIVATE_KEY = content of ~/.abuild/yourname-xxxxxxxx.rsa
#    NEW_RSA_PUBLIC_KEY = content of ~/.abuild/yourname-xxxxxxxx.rsa.pub

# 3. Run workflow manually
#    Actions → Sign and Publish → Run workflow
#    alpine-version: v3.19
#    force-resign: false  (rotation will re-sign anyway)

# 4. After successful run, update secrets:
#    RSA_PRIVATE_KEY = (copy from NEW_RSA_PRIVATE_KEY)
#    RSA_PUBLIC_KEY = (copy from NEW_RSA_PUBLIC_KEY)
#    Delete NEW_RSA_PRIVATE_KEY
#    Delete NEW_RSA_PUBLIC_KEY

# 5. Users update their keyring:
wget https://jambox-it.github.io/aports/keys/jambox-newfingerprint.rsa.pub
sudo cp jambox-newfingerprint.rsa.pub /etc/apk/keys/
```
