#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Emojiz"
INSTALL_DIR="/opt/${APP_NAME}"
BIN_PATH="${INSTALL_DIR}/${APP_NAME}"
SYMLINK_PATH="/usr/bin/${APP_NAME}"
CHROME_SANDBOX="${INSTALL_DIR}/chrome-sandbox"

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"
chmod +x "$SCRIPT_PATH" 2>/dev/null || true

if [ -f "$CHROME_SANDBOX" ]; then
  chown root:root "$CHROME_SANDBOX" 2>/dev/null || true
  chmod 4755 "$CHROME_SANDBOX" 2>/dev/null || true
fi

if [ -x "$BIN_PATH" ]; then

  ln -sf "$BIN_PATH" "$SYMLINK_PATH" 2>/dev/null || true
  chmod +x "$BIN_PATH" 2>/dev/null || true
fi

SHORTCUT_BINDING="<Control>semicolon"
SHORTCUT_NAME="Launch ${APP_NAME}"
SHORTCUT_COMMAND="${APP_NAME}"

print() { [ -t 1 ] && printf '%s\n' "$*"; }

if command -v gsettings >/dev/null 2>&1; then
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

  print "✅ Shortcut configured (if running GNOME). Press Ctrl+; to open ${APP_NAME} (if GNOME)."
fi

set -e

DESKTOP_FILE="/usr/share/applications/emojiz.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    if ! grep -q "StartupWMClass=emojiz" "$DESKTOP_FILE"; then
        echo "StartupWMClass=emojiz" | sudo tee -a "$DESKTOP_FILE" > /dev/null
    fi
fi

exit 0
