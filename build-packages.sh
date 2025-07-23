#!/bin/bash

# YaLL Package Builder Script
# Builds deb and rpm packages for distribution

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.2"
    exit 1
fi

echo "Building YaLL packages for version $VERSION..."

# Verify release binary exists
RELEASE_DIR="releases/v$VERSION"
BINARY_DIR="$RELEASE_DIR/yall-$VERSION-linux-x64"

if [ ! -d "$BINARY_DIR" ]; then
    echo "Error: Release binary not found at $BINARY_DIR"
    echo "Please run ./build-release.sh $VERSION first"
    exit 1
fi

echo "Creating packages from $BINARY_DIR..."

# Create packaging workspace
PKG_WORK_DIR="/tmp/yall-packaging-$VERSION"
rm -rf "$PKG_WORK_DIR"
mkdir -p "$PKG_WORK_DIR"

# Copy binary for packaging
cp -r "$BINARY_DIR" "$PKG_WORK_DIR/"

cd "$PKG_WORK_DIR"

# =============================================================================
# BUILD DEB PACKAGE
# =============================================================================
echo "Building .deb package..."

DEB_DIR="yall-$VERSION-deb"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"
mkdir -p "$DEB_DIR/usr/share/doc/yall"

# Copy binary and dependencies to application directory
mkdir -p "$DEB_DIR/usr/lib/yall"
cp -r "yall-$VERSION-linux-x64/"* "$DEB_DIR/usr/lib/yall/"

# Create wrapper script in /usr/bin
cat > "$DEB_DIR/usr/bin/yall" << 'WRAPPER_EOF'
#!/bin/bash
exec /usr/lib/yall/yall "$@"
WRAPPER_EOF
chmod +x "$DEB_DIR/usr/bin/yall"

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: yall
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libglib2.0-0
Maintainer: Tim Apple <tim@timapple.com>
Description: Multi-platform social media poster
 Yall is a Flutter-based cross-platform social media poster that lets you
 send messages to multiple social platforms simultaneously. Supports Nostr,
 Bluesky, and Mastodon with smart character limits and content truncation.
Homepage: https://github.com/timappledotcom/yall
EOF

# Create desktop entry
cat > "$DEB_DIR/usr/share/applications/yall.desktop" << EOF
[Desktop Entry]
Name=Yall
Comment=Multi-platform social media poster
Exec=/usr/bin/yall
Icon=yall
Terminal=false
Type=Application
Categories=Network;
EOF

# Create copyright file with MIT license
cat > "$DEB_DIR/usr/share/doc/yall/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: yall
Source: https://github.com/timappledotcom/yall

Files: *
Copyright: 2024-2025 Tim Apple
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# Build deb package
dpkg-deb --build "$DEB_DIR" "yall-$VERSION.deb"

# =============================================================================
# BUILD RPM PACKAGE
# =============================================================================
echo "Building .rpm package..."

# Create RPM build environment
RPM_BUILD_DIR="rpmbuild"
mkdir -p "$RPM_BUILD_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Create source tarball
tar -czf "$RPM_BUILD_DIR/SOURCES/yall-$VERSION.tar.gz" "yall-$VERSION-linux-x64"

# Create RPM spec file
cat > "$RPM_BUILD_DIR/SPECS/yall.spec" << EOF
Name:           yall
Version:        $VERSION
Release:        1%{?dist}
Summary:        Multi-platform social media poster

License:        MIT
URL:            https://github.com/timappledotcom/yall
Source0:        yall-%{version}.tar.gz

BuildArch:      x86_64
Requires:       gtk3, glib2

%description
Yall is a Flutter-based cross-platform social media poster that lets you
send messages to multiple social platforms simultaneously. Supports Nostr,
Bluesky, and Mastodon with smart character limits and content truncation.

%prep
%setup -q -n yall-%{version}-linux-x64

%install
mkdir -p %{buildroot}/usr/lib/yall
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
cp -r * %{buildroot}/usr/lib/yall/

# Create wrapper script
cat > %{buildroot}/usr/bin/yall << 'WRAPPER_EOF'
#!/bin/bash
exec /usr/lib/yall/yall "$@"
WRAPPER_EOF
chmod +x %{buildroot}/usr/bin/yall

cat > %{buildroot}/usr/share/applications/yall.desktop << DESKTOP_EOF
[Desktop Entry]
Name=Yall
Comment=Multi-platform social media poster
Exec=/usr/bin/yall
Icon=yall
Terminal=false
Type=Application
Categories=Network;
DESKTOP_EOF

%files
/usr/lib/yall/*
/usr/bin/yall
/usr/share/applications/yall.desktop

%changelog
* $(date +'%a %b %d %Y') Tim Apple <tim@timapple.com> - $VERSION-1
- Release $VERSION with MIT license and updated dependencies
EOF

# Build RPM
rpmbuild --define "_topdir $PWD/$RPM_BUILD_DIR" -ba "$RPM_BUILD_DIR/SPECS/yall.spec"

# =============================================================================
# COPY PACKAGES BACK TO RELEASE DIRECTORY
# =============================================================================
echo "Copying packages to release directory..."

# Go back to project root
cd - > /dev/null

# Copy packages to release directory
cp "$PKG_WORK_DIR/yall-$VERSION.deb" "$RELEASE_DIR/"
cp "$PKG_WORK_DIR/$RPM_BUILD_DIR/RPMS/x86_64/yall-$VERSION-1."*.rpm "$RELEASE_DIR/"
cp "$PKG_WORK_DIR/$RPM_BUILD_DIR/SRPMS/yall-$VERSION-1."*.src.rpm "$RELEASE_DIR/"

# Generate checksums
cd "$RELEASE_DIR"
echo "Generating checksums..."
sha256sum *.deb *.rpm *.tar.gz > SHA256SUMS

echo ""
echo "✅ Package build complete!"
echo "📦 Packages created:"
ls -la *.deb *.rpm 2>/dev/null || echo "Packages built successfully"
echo ""
echo "📁 Release directory: $RELEASE_DIR"
echo "🔍 Checksums: SHA256SUMS"

# Cleanup
rm -rf "$PKG_WORK_DIR"

echo "🧹 Temporary files cleaned up"
echo "🎉 Ready for release publishing!"
