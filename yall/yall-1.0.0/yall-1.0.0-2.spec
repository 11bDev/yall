Buildroot: /home/tim/Projects/Main/yall/yall/yall-1.0.0
Name: yall
Version: 1.0.0
Release: 2
Summary: Multi-platform social media poster
License: see /usr/share/doc/yall/copyright
Distribution: Debian
Group: Converted/utils

%define _rpmdir ../
%define _rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm
%define _unpackaged_files_terminate_build 0

%description
Yall is a Flutter-based cross-platform social media poster that lets you 
send messages to multiple social platforms simultaneously. Supports Nostr, 
Bluesky, and Mastodon with smart character limits and content truncation.


(Converted from a deb package by alien version 8.95.8.)

%files
%dir "/usr/bin/data/"
%dir "/usr/bin/data/flutter_assets/"
"/usr/bin/data/flutter_assets/AssetManifest.bin"
"/usr/bin/data/flutter_assets/AssetManifest.json"
"/usr/bin/data/flutter_assets/FontManifest.json"
"/usr/bin/data/flutter_assets/NOTICES.Z"
"/usr/bin/data/flutter_assets/NativeAssetsManifest.json"
%dir "/usr/bin/data/flutter_assets/assets/"
%dir "/usr/bin/data/flutter_assets/assets/icons/"
"/usr/bin/data/flutter_assets/assets/icons/app_icon.png"
"/usr/bin/data/flutter_assets/assets/icons/tray_icon.ico"
"/usr/bin/data/flutter_assets/assets/icons/tray_icon.png"
"/usr/bin/data/flutter_assets/assets/icons/tray_icon.svg"
%dir "/usr/bin/data/flutter_assets/fonts/"
"/usr/bin/data/flutter_assets/fonts/MaterialIcons-Regular.otf"
%dir "/usr/bin/data/flutter_assets/packages/"
%dir "/usr/bin/data/flutter_assets/packages/cupertino_icons/"
%dir "/usr/bin/data/flutter_assets/packages/cupertino_icons/assets/"
"/usr/bin/data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf"
%dir "/usr/bin/data/flutter_assets/shaders/"
"/usr/bin/data/flutter_assets/shaders/ink_sparkle.frag"
"/usr/bin/data/flutter_assets/version.json"
"/usr/bin/data/icudtl.dat"
%dir "/usr/bin/lib/"
"/usr/bin/lib/libapp.so"
"/usr/bin/lib/libflutter_linux_gtk.so"
"/usr/bin/lib/libflutter_secure_storage_linux_plugin.so"
"/usr/bin/lib/libscreen_retriever_linux_plugin.so"
"/usr/bin/lib/libsystem_tray_plugin.so"
"/usr/bin/lib/libwindow_manager_plugin.so"
"/usr/bin/yall"
%dir "/usr/share/applications/"
"/usr/share/applications/yall.desktop"
%dir "/usr/share/icons/hicolor/"
%dir "/usr/share/icons/hicolor/512x512/"
%dir "/usr/share/icons/hicolor/512x512/apps/"
"/usr/share/icons/hicolor/512x512/apps/yall.png"
