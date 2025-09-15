#!/bin/bash

cat > /usr/bin/emojispicker-launcher <<'EOF'
#!/bin/bash

if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ "$WAYLAND_DISPLAY" ]; then

    exec /opt/EmojisPicker/EmojisPicker \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations \
        --ozone-platform-hint=auto \
        --enable-wayland-ime \
        "$@"
else

    exec /opt/EmojisPicker/EmojisPicker "$@"
fi
EOF

chmod +x /usr/bin/emojispicker-launcher

if [ -f /usr/share/applications/emojispicker.desktop ]; then
    sed -i 's|Exec=.*|Exec=/usr/bin/emojispicker-launcher %U|' /usr/share/applications/emojispicker.desktop
fi

update-desktop-database /usr/share/applications 2>/dev/null || true
