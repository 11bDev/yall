Name:           yall
Version:        1.0.1
Release:        1%{?dist}
Summary:        Multi-Platform Social Media Poster
Group:          Applications/Internet
License:        MIT
URL:            https://github.com/timappledotcom/yall
Source0:        %{name}-%{version}.tar.gz
BuildArch:      x86_64
Requires:       gtk3, glib2

%description
YaLL (Yet another Link Logger) is a desktop application that allows you to
post messages to multiple social media platforms simultaneously including
Nostr, Bluesky, and Mastodon.

Features:
- Post to multiple platforms at once
- Secure credential management  
- Character limit validation per platform
- System tray integration
- Dark and light themes

%prep
%setup -q

%build
# Nothing to build, pre-compiled binary

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/lib/yall
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/pixmaps

# Copy application files
cp -r * %{buildroot}/usr/lib/yall/

# Create launcher script
cat > %{buildroot}/usr/bin/yall << 'EOF'
#!/bin/bash
exec /usr/lib/yall/yall "$@"
EOF
chmod +x %{buildroot}/usr/bin/yall

# Create desktop entry
cat > %{buildroot}/usr/share/applications/yall.desktop << 'EOF'
[Desktop Entry]
Name=YaLL
Comment=Multi-Platform Social Media Poster
GenericName=Social Media Client
Exec=yall
Icon=yall
StartupNotify=true
NoDisplay=false
Categories=Network;InstantMessaging;
Type=Application
Terminal=false
MimeType=text/plain;
Keywords=social;media;nostr;bluesky;mastodon;posting;
EOF

# Copy icon if it exists
if [ -f "%{_sourcedir}/app_icon.png" ]; then
    cp "%{_sourcedir}/app_icon.png" %{buildroot}/usr/share/pixmaps/yall.png
fi

%files
%defattr(-,root,root,-)
/usr/lib/yall/
/usr/bin/yall
/usr/share/applications/yall.desktop
/usr/share/pixmaps/yall.png

%changelog
* Mon Jul 22 2024 Tim Apple <tim@appledotcom> - 1.0.1-1
- Updated Nostr character limit to 800 characters
- Fixed NostrService private key validation logic
- Enhanced error handling in credential validation
- Added proper timeout handling for WebSocket connections
- Updated all related tests to reflect new character limit
- Fixed test infrastructure to prevent hanging issues

* Mon Jul 15 2024 Tim Apple <tim@appledotcom> - 1.0.0-1
- Initial release
- Multi-platform posting support for Nostr, Bluesky, and Mastodon
- System tray integration
- Account management with secure storage
- Character limit validation
