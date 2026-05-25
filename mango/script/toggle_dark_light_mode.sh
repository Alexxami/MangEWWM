#!/bin/bash

# ============================================================
# Toggle dark/light theme - Funciona desde keybindings
# ============================================================

# Archivo de estado
STATE_FILE="/tmp/toggle_script_state"

# Inicializar estado (0=oscuro, 1=claro)
[[ -f "$STATE_FILE" ]] || echo 0 > "$STATE_FILE"
STATE=$(cat "$STATE_FILE")

# ------------------------------------------------------------------
# Función para recargar Kitty sin reiniciar
# Usa SIGUSR1 (no requiere entorno ni control remoto)
# ------------------------------------------------------------------
reload_kitty() {
    if pkill -SIGUSR1 kitty 2>/dev/null; then
        echo "[Kitty] Configuración recargada (SIGUSR1)"
    else
        echo "[Kitty] No se encontraron procesos de Kitty"
    fi
}

# ------------------------------------------------------------------
# Aplicar tema según STATE
# ------------------------------------------------------------------
if [[ "$STATE" -eq 0 ]]; then
    echo "🔄 Aplicando tema OSCURO"

    # Kitty
    cp /home/dafne/.config/kitty/colors-dark.conf /home/dafne/.config/kitty/colors.conf

    # Waybar
    cp /home/dafne/.config/mango/script/waybar-dark.sh /home/dafne/.config/mango/script/waybar.sh

    # EWW
    cp /home/dafne/.config/eww/eww-dark.scss /home/dafne/.config/eww/eww.scss

    # Rofi imágenes
    cp /home/dafne/.config/rofi/images/gruvcolors-dark.png /home/dafne/.config/rofi/images/gruvcolors.png

    # Hyprlock
    cp /home/dafne/.config/hypr/hyprlock-dark.conf /home/dafne/.config/hypr/hyprlock.conf

    # Rofi launcher
    cp /home/dafne/.config/rofi/launchers/type-7/launcher-dark.sh /home/dafne/.config/rofi/launchers/type-7/launcher.sh
    

    # Dunst
    rm /home/dafne/.config/dunst/dunstrc
    cp /home/dafne/.config/dunst/dunstrc-dark /home/dafne/.config/dunst/dunstrc
    pkill dunst; dunst &

    # Rofi .rasi (applets, powermenu, etc.)
       rm /home/dafne/.config/rofi/applets/shared/colors-fallback.rasi /home/dafne/.config/rofi/files/shared/colors-fallback.rasi /home/dafne/.config/rofi/powermenu/colors-fallback.rasi /home/dafne/.config/rofi/quicklinks/shared/colors-fallback.rasi /home/dafne/.config/rofi/launchers/type-7/launcher.sh
    cp /home/dafne/.config/rofi/launchers/type-7/launcher-dark.sh /home/dafne/.config/rofi/launchers/type-7/launcher.sh
    cp /home/dafne/.config/rofi/colors-dark.rasi /home/dafne/.config/rofi/applets/shared/colors-fallback.rasi 
    cp /home/dafne/.config/rofi/colors-dark.rasi /home/dafne/.config/rofi/files/shared/colors-fallback.rasi
    cp /home/dafne/.config/rofi/colors-dark.rasi /home/dafne/.config/rofi/powermenu/colors-fallback.rasi
    cp /home/dafne/.config/rofi/colors-dark.rasi  /home/dafne/.config/rofi/quicklinks/shared/colors-fallback.rasi
    # Caso específico para launcher.sh ya está arriba

    # Vesktop
    cp /home/dafne/.config/vesktop/themes/midnight-nord-dark.theme.css /home/dafne/.config/vesktop/themes/nord.css

    # Recargar Kitty
    reload_kitty

    # Cambiar estado para la próxima
    echo 1 > "$STATE_FILE"
else
    echo "🔄 Aplicando tema CLARO"

    # Kitty
    cp /home/dafne/.config/kitty/colors-light.conf /home/dafne/.config/kitty/colors.conf

    # Waybar
    cp /home/dafne/.config/mango/script/waybar-light.sh /home/dafne/.config/mango/script/waybar.sh

    # EWW
    cp /home/dafne/.config/eww/eww-light.scss /home/dafne/.config/eww/eww.scss

    # Rofi imágenes
    cp /home/dafne/.config/rofi/images/gruvcolors-light.png /home/dafne/.config/rofi/images/gruvcolors.png

    # Hyprlock
    cp /home/dafne/.config/hypr/hyprlock-light.conf /home/dafne/.config/hypr/hyprlock.conf

    # Rofi launcher
    cp /home/dafne/.config/rofi/launchers/type-7/launcher-light.sh /home/dafne/.config/rofi/launchers/type-7/launcher.sh

    # Dunst
    rm /home/dafne/.config/dunst/dunstrc
    cp /home/dafne/.config/dunst/dunstrc-light /home/dafne/.config/dunst/dunstrc
    pkill dunst; dunst &

    # Rofi .rasi
       rm /home/dafne/.config/rofi/applets/shared/colors-fallback.rasi /home/dafne/.config/rofi/files/shared/colors-fallback.rasi /home/dafne/.config/rofi/powermenu/colors-fallback.rasi /home/dafne/.config/rofi/quicklinks/shared/colors-fallback.rasi /home/dafne/.config/rofi/launchers/type-7/launcher.sh
    cp /home/dafne/.config/rofi/launchers/type-7/launcher-light.sh /home/dafne/.config/rofi/launchers/type-7/launcher.sh
    cp /home/dafne/.config/rofi/colors-light.rasi /home/dafne/.config/rofi/applets/shared/colors-fallback.rasi 
    cp /home/dafne/.config/rofi/colors-light.rasi /home/dafne/.config/rofi/files/shared/colors-fallback.rasi
    cp /home/dafne/.config/rofi/colors-light.rasi /home/dafne/.config/rofi/powermenu/colors-fallback.rasi
    cp /home/dafne/.config/rofi/colors-light.rasi  /home/dafne/.config/rofi/quicklinks/shared/colors-fallback.rasi
    # Caso específico para launcher.sh ya está arriba

    # Vesktop
    cp /home/dafne/.config/vesktop/themes/midnight-nord-light.theme.css /home/dafne/.config/vesktop/themes/nord.css

    # Recargar Kitty
    reload_kitty


    echo 0 > "$STATE_FILE"
fi

set_firefox_theme() {
    local BASE_DIR="$HOME/.config/mozilla/firefox"
    local PROFILES_INI="$BASE_DIR/profiles.ini"
    
    [[ ! -f "$PROFILES_INI" ]] && return 0

    local DEFAULT_PROFILE=$(awk -F= '/^Default=/{print $2}' "$PROFILES_INI" | head -1)
    [[ -z "$DEFAULT_PROFILE" ]] && return 0

    local PREFS="$BASE_DIR/$DEFAULT_PROFILE/prefs.js"
    [[ ! -f "$PREFS" ]] && return 0

    # Eliminar línea existente
    sed -i '/user_pref("ui.systemUsesDarkTheme",/d' "$PREFS"

    if [[ "$STATE" -eq 0 ]]; then
        # Modo oscuro
        echo 'user_pref("ui.systemUsesDarkTheme", 1);' >> "$PREFS"
        notify-send -t 3000 -i firefox "Firefox" "Tema oscuro listo. Reinicia Firefox."
    else
        # Modo claro
        echo 'user_pref("ui.systemUsesDarkTheme", 0);' >> "$PREFS"
        notify-send -t 3000 -i firefox "Firefox" "Tema claro listo. Reinicia Firefox."
    fi
}



exit 0