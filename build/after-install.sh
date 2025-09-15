#!/usr/bin/env bash
set -euo pipefail

# build/after-install.sh
# Ensures it's executable, fixes Electron sandbox permissions,
# then creates a GNOME custom shortcut that runs "Emojiz".
# This script is safe to be used as FPM/DEB --after-install / maintainer script.

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"
if [ ! -x "$SCRIPT_PATH" ]; then
    chmod +x "$SCRIPT_PATH" 2>/dev/null || true
fi

APP_NAME="Emojiz"
SHORTCUT_BINDING="<Control>semicolon"  
SHORTCUT_NAME="Launch ${APP_NAME}"
SHORTCUT_COMMAND="${APP_NAME}"

print() {
    if [ -t 1 ]; then
        echo -e "$@"
    fi
}

### 🔧 Fix Electron sandbox permissions
if [ -f "/opt/${APP_NAME}/chrome-sandbox" ]; then
    chown root:root "/opt/${APP_NAME}/chrome-sandbox" || true
    chmod 4755 "/opt/${APP_NAME}/chrome-sandbox" || true
    print "✅ Sandbox permissions fixed for /opt/${APP_NAME}/chrome-sandbox"
fi

### 🎹 GNOME shortcut setup
if ! command -v gsettings >/dev/null 2>&1; then
    print "⚠️  gsettings not found — skipping GNOME shortcut setup."
    exit 0
fi

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_UID="$(id -u "$TARGET_USER")"

gsettings_exec() {
    if [ -n "${SUDO_USER:-}" ]; then
        sudo -u "$TARGET_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$TARGET_UID/bus" \
            gsettings "$@"
    else
        gsettings "$@"
    fi
}

SANITIZED_NAME="$(echo "$APP_NAME" | tr -cd '[:alnum:]_')"
CUSTOM_KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom_${SANITIZED_NAME}/"

KEYBINDING_LIST_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KEYBINDING_LIST_KEY="custom-keybindings"
INDIVIDUAL_KEY_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KEY_PATH}"

current_bindings="$(gsettings_exec get "$KEYBINDING_LIST_SCHEMA" "$KEYBINDING_LIST_KEY" 2>/dev/null || echo "@as []")"
if [[ "$current_bindings" != *"$CUSTOM_KEY_PATH"* ]]; then
    if [[ "$current_bindings" == "@as []" || "$current_bindings" == "[]" ]]; then
        new_bindings="['$CUSTOM_KEY_PATH']"
    else
        new_bindings="${current_bindings%]*}, '$CUSTOM_KEY_PATH']"
    fi
    gsettings_exec set "$KEYBINDING_LIST_SCHEMA" "$KEYBINDING_LIST_KEY" "$new_bindings" 2>/dev/null || true
fi

gsettings_exec set "$INDIVIDUAL_KEY_SCHEMA" name    "$SHORTCUT_NAME" 2>/dev/null || true
gsettings_exec set "$INDIVIDUAL_KEY_SCHEMA" command "$SHORTCUT_COMMAND" 2>/dev/null || true
gsettings_exec set "$INDIVIDUAL_KEY_SCHEMA" binding "$SHORTCUT_BINDING" 2>/dev/null || true

print "✅  Shortcut configured (if running GNOME). Press Ctrl+; to open $APP_NAME (if GNOME)."

exit 0
