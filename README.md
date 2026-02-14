# JamBox Alpine Packages Repository

Alpine Linux packages for JamBox IoT platform and related tools.

## Build Status

| Branch | Status |
|--------|----------------|--------|
| `main` | [![Build](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml/badge.svg?branch=main)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml?query=branch%3Amain) |
| `v3.19` | [![Build](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml/badge.svg?branch=v3.19)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml?query=branch%3Av3.19) |
| `v3.23` | [![Build](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml/badge.svg?branch=v3.23)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml?query=branch%3Av3.23) |

**Validation:** [![Package Validation](https://github.com/JamBox-IT/aports/actions/workflows/validate-packages.yml/badge.svg)](https://github.com/JamBox-IT/aports/actions/workflows/validate-packages.yml)

---

## Overview

This repository contains Alpine Linux package definitions (APKBUILD files) for:

- **Solar monitoring** (py3-mppsolar, py3-mppsolar-ex)
- **Meshtastic** mesh radio communication
- **Prometheus exporters** (weather data, mesh metrics)
- **System tools** (alpine-jbase, acf-jbskin)
- **Python dependencies** for embedded deployment

All packages are built automatically via CI/CD for multiple architectures.

---

## Repository Structure

```
aports/
├── JamBox/              # Main package repository
│   ├── py3-mppsolar/    # Example package
│   │   └── APKBUILD
│   ├── py3-meshtastic/
│   └── ...
├── testing/             # Experimental packages
│   └── py3-mppsolar-ex/
└── .github/
    └── workflows/       # CI/CD automation
```

---

## Automated Builds (CI/CD)

**Every push to main automatically:**
- ✅ Validates APKBUILD syntax and security
- ✅ Builds packages for 4 architectures (x86_64, aarch64, armv7, armhf)
- ✅ Creates GitHub releases with downloadable .apk files

### Quick Start

See: `../DEV_DOC/CICD_QUICK_START.md` for 10-minute setup

### Documentation

- **Full Guide:** `../DEV_DOC/CICD_SETUP_GUIDE.md`
- **Workflow Logs:** [GitHub Actions](https://github.com/JamBox-IT/aports/actions)
- **Releases:** [Releases Page](https://github.com/JamBox-IT/aports/releases)

---

## Package Development

### Adding a New Package

```bash
# 1. Create package directory
cd JamBox/
mkdir py3-newpackage
cd py3-newpackage

# 2. Create APKBUILD
cat > APKBUILD << 'EOF'
# Contributor: Corey DeLasaux <cordelster@gmail.com>
# Maintainer: Corey DeLasaux <cordelster@gmail.com>
pkgname=py3-newpackage
pkgver=1.0.0
pkgrel=0
pkgdesc="Package description"
url="https://example.com"
arch="noarch"
license="MIT"
depends="python3"
makedepends="py3-setuptools py3-gpep517 py3-wheel"
source="https://files.pythonhosted.org/.../newpackage-$pkgver.tar.gz"
builddir="$srcdir/newpackage-$pkgver"

build() {
    gpep517 build-wheel --wheel-dir .dist --output-fd 3 3>&1 >&2
}

package() {
    gpep517 install-wheel --destdir "$pkgdir" .dist/*.whl
}

sha512sums=""
EOF

# 3. Commit and push
git add APKBUILD
git commit -m "Add py3-newpackage"
git push origin main

# CI/CD will automatically build and release
```

### Updating an Existing Package

```bash
cd JamBox/py3-mppsolar

# Edit version
sed -i '' 's/pkgver=.*/pkgver=0.17.0/' APKBUILD

# Update checksums if needed
# (CI will validate)

# Commit and push
git add APKBUILD
git commit -m "Update py3-mppsolar to 0.17.0"
git push origin main

# Wait ~20 minutes for builds to complete
# Download from Releases page
```

---

## Manual Building (Local Testing)

For local testing before pushing:

```bash
# Using dabuild (requires docker-abuild)
cd JamBox/py3-mppsolar

DABUILD_ARCH=armhf \
DABUILD_PACKAGES=/tmp/packages \
DABUILD_VERSION=edge \
../../../docker-abuild/dabuild -r
```

See: `../CLAUDE.md` for detailed dabuild usage

---

## Architectures Supported

- **x86_64** - Intel/AMD 64-bit
- **aarch64** - ARM 64-bit (Raspberry Pi 4, etc.)
- **armv7** - ARM 32-bit (Raspberry Pi 3, etc.)
- **armhf** - ARM Hard Float

---

## Package Naming Conventions

- **py3-*** - Python 3 packages
- **acf-*** - Alpine Configuration Framework components
- **prometheus-*** - Prometheus exporters

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Push and create a pull request
5. CI will automatically validate and build
6. Merge when ready

---

## Installation

### From GitHub Releases

```bash
# Download package for your architecture
wget https://github.com/JamBox-IT/aports/releases/download/<release>/<package>.apk

# Install
apk add --allow-untrusted <package>.apk
```

### As Alpine Repository (Future)

Coming soon: Hosted Alpine repository for easier installation

---

## Documentation

- **CI/CD Setup:** `../DEV_DOC/CICD_SETUP_GUIDE.md`
- **Quick Start:** `../DEV_DOC/CICD_QUICK_START.md`
- **Claude Guide:** `../CLAUDE.md`
- **Kanidm RADIUS:** `../DEV_DOC/ALPINE_RADIUS_PACKAGE_TODO.md`

---

## Workflow Status

Check current build status: [Actions Tab](https://github.com/JamBox-IT/aports/actions)

**Workflows:**
- **Build Alpine Packages** - Multi-arch package building
- **Validate Packages** - Syntax and security validation
- **Release** - Automatic release creation (legacy)

---

## License

Individual packages may have different licenses. See each package's APKBUILD for details.

---

## Maintainer

**Corey DeLasaux** <cordelster@gmail.com>

**Organization:** [JamBox IT](https://github.com/JamBox-IT)

---

## Links

- **Repository:** https://github.com/JamBox-IT/aports
- **Actions:** https://github.com/JamBox-IT/aports/actions
- **Releases:** https://github.com/JamBox-IT/aports/releases
- **Issues:** https://github.com/JamBox-IT/aports/issues
