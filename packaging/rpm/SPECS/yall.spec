Name:           yall
Version:        1.0.0
Release:        1%{?dist}
Summary:        Multi-platform social media poster

License:        MIT
URL:            https://github.com/timappledotcom/yall
Source0:        yall-1.0.0.tar.gz

BuildArch:      x86_64
Requires:       gtk3, glib2

%description
Yall is a Flutter-based cross-platform social media poster that lets you 
send messages to multiple social platforms simultaneously. Supports Nostr, 
Bluesky, and Mastodon with smart character limits and content truncation.

%prep
%setup -q

%build
# Nothing to build, pre-compiled binary

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/512x512/apps

cp -r * %{buildroot}/usr/bin/
cp yall.desktop %{buildroot}/usr/share/applications/
cp app_icon.png %{buildroot}/usr/share/icons/hicolor/512x512/apps/yall.png

%files
/usr/bin/*
/usr/share/applications/yall.desktop
/usr/share/icons/hicolor/512x512/apps/yall.png

%changelog
* $(date "+%a %b %d %Y") Tim Apple <tim@example.com> - 1.0.0-1
- Initial release with smart character limits and content truncation
