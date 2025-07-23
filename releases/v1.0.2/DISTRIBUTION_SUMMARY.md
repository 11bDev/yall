# YaLL v1.0.2 Distribution Summary

**Release Date:** July 22, 2025  
**License:** MIT  
**Architecture:** x86_64/amd64  

## 📦 Package Information

### Generic Linux Binary
- **File:** `yall-1.0.2-linux-x64.tar.gz`
- **Size:** 19MB
- **Format:** Compressed tarball
- **Installation:** Extract and run `./yall`
- **Dependencies:** GTK3, GLib2 (usually pre-installed)

### Debian Package (.deb)
- **File:** `yall-1.0.2.deb`
- **Size:** 15MB
- **Compatible:** Ubuntu, Debian, Linux Mint, Pop!_OS, Elementary OS
- **Installation:** `sudo dpkg -i yall-1.0.2.deb && sudo apt-get install -f`
- **Dependencies:** Auto-resolved (libgtk-3-0, libglib2.0-0)

### RPM Package (.rpm)
- **File:** `yall-1.0.2-1.x86_64.rpm`
- **Size:** 11MB
- **Compatible:** Fedora, CentOS, RHEL, openSUSE, Mandriva
- **Installation:** `sudo rpm -i yall-1.0.2-1.x86_64.rpm` or `sudo dnf install yall-1.0.2-1.x86_64.rpm`
- **Dependencies:** Auto-resolved (gtk3, glib2)

### Source RPM (.src.rpm)
- **File:** `yall-1.0.2-1.src.rpm`
- **Size:** 19MB
- **Purpose:** Source package for building from source on RPM-based systems
- **Usage:** `rpmbuild --rebuild yall-1.0.2-1.src.rpm`

## 🔐 Security & Verification

### SHA256 Checksums
```
220350aa4b5c16200bc65301d803abaa5172ac7084398966bb18cbed50b8906e  yall-1.0.2.deb
4c1d2704cc3edd6982d1b94857b429eddbe6c8562c7a51625bb081a5148cc884  yall-1.0.2-1.src.rpm
c727ec0122ce3fd6a5af4cb64cd89add6d8d3822a8d34f6f2eb7d1e2900f0690  yall-1.0.2-1.x86_64.rpm
d1543a6af1b3727df6f4c642e7c2baaa8c0b07430564ec44c5288fc441e78554  yall-1.0.2-linux-x64.tar.gz
```

### Verification
```bash
# Verify checksums
sha256sum -c SHA256SUMS

# Verify package signatures (if available)
dpkg --verify yall-1.0.2.deb      # Debian
rpm --verify yall-1.0.2-1.x86_64.rpm  # RPM
```

## 🚀 Installation Instructions

### Ubuntu/Debian
```bash
# Download and install
wget https://github.com/timappledotcom/yall/releases/download/v1.0.2/yall-1.0.2.deb
sudo dpkg -i yall-1.0.2.deb
sudo apt-get install -f  # Install any missing dependencies
```

### Fedora/CentOS/RHEL
```bash
# Download and install
wget https://github.com/timappledotcom/yall/releases/download/v1.0.2/yall-1.0.2-1.x86_64.rpm
sudo dnf install yall-1.0.2-1.x86_64.rpm
# or: sudo rpm -i yall-1.0.2-1.x86_64.rpm
```

### Generic Linux
```bash
# Download and extract
wget https://github.com/timappledotcom/yall/releases/download/v1.0.2/yall-1.0.2-linux-x64.tar.gz
tar -xzf yall-1.0.2-linux-x64.tar.gz
cd yall-1.0.2-linux-x64
./yall
```

## 🆕 What's New in v1.0.2

- **License Change:** Now MIT licensed (previously GPL-3.0+)
- **Updated Dependencies:** Latest Flutter packages for better stability
- **About Page:** Comprehensive system information and app details
- **Build Process:** Automated packaging for multiple distributions
- **Package Quality:** Improved .deb and .rpm packages with proper dependencies

## 📋 System Requirements

- **OS:** Linux x86_64 (64-bit)
- **Desktop Environment:** Any GTK3-compatible environment
- **RAM:** 512MB minimum, 1GB recommended
- **Storage:** 100MB free space
- **Network:** Internet connection for social platform access

## 🔗 Platform Support

- ✅ **Nostr:** Full relay support with key management
- ✅ **Bluesky:** AT Protocol integration
- ✅ **Mastodon:** ActivityPub federation support
- ✅ **System Tray:** Minimize to tray functionality
- ✅ **Window Management:** State persistence and restoration

## 📞 Support

- **Issues:** https://github.com/timappledotcom/yall/issues
- **Discussions:** https://github.com/timappledotcom/yall/discussions
- **Documentation:** https://github.com/timappledotcom/yall/blob/main/README.md

## 📄 License

This software is released under the MIT License. See the LICENSE file for details.
