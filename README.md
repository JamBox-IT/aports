# JamBox Alpine Packages Repository

Alpine Linux packages for JamBox IoT platform and related tools.

## Build Status

[![main (Alpine edge)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml/badge.svg?branch=main)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml?query=branch%3Amain)
[![v3.19 (Alpine 3.19)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml/badge.svg?branch=v3.19)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml?query=branch%3Av3.19)
[![v3.23 (Alpine 3.23)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml/badge.svg?branch=v3.23)](https://github.com/JamBox-IT/aports/actions/workflows/build-and-release.yml?query=branch%3Av3.23)

[![Package Validation](https://github.com/JamBox-IT/aports/actions/workflows/validate-packages.yml/badge.svg)](https://github.com/JamBox-IT/aports/actions/workflows/validate-packages.yml)

---

## Overview

This repository contains Alpine Linux package definitions (APKBUILD files) for:

- **Solar monitoring** (py3-mppsolar, py3-mppsolar-ex)
- **Meshtastic** mesh radio communication
- **Prometheus exporters** (weather data, mesh metrics)
- **System tools** (alpine-jbase, acf-jbskin)
- **Python dependencies** for embedded deployment
- **kanidm** Kanidm is an identity management server, acting as an authority on account information

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
