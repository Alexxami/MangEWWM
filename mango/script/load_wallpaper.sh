#!/bin/bash
# ~/.config/i3/scripts/load_wallpaper.sh
# Script para cargar el wallpaper guardado (soporta imágenes y videos con wallset)

CONFIG_FILE="$HOME/.config/wallpaper_config.json"
DEFAULT_WALLPAPER="$HOME/.config/i3/wallpaper.png"
LOG_FILE="/tmp/wallpaper_loader.log"

# Función para loguear mensajes
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Verificar si wallset está instalado
check_wallset() {
    if ! command -v wallset &> /dev/null; then
        log_message "Error: wallset no está instalado"
        echo "Error: wallset no está instalado. Instálalo con: pip install wallset" >&2
        return 1
    fi
    return 0
}

# Función para aplicar wallpaper según el tipo de archivo
apply_wallpaper() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_message "Error: Archivo no encontrado: $file"
        return 1
    fi
    
    # Detectar si es video por extensión
    case "${file,,}" in
        *.mp4|*.webm|*.mov|*.avi|*.mkv|*.gif)
            log_message "Aplicando video wallpaper: $file"
            wallset --video "$file"
            ;;
        *.png|*.jpg|*.jpeg|*.webp|*.bmp)
            log_message "Aplicando imagen wallpaper: $file"
            wallset --img "$file"
            ;;
        *)
            log_message "Formato no soportado: $file"
            echo "Formato no soportado: $file" >&2
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        log_message "Wallpaper aplicado correctamente: $file"
        return 0
    else
        log_message "Error al aplicar wallpaper: $file"
        return 1
    fi
}

# Función para obtener wallpaper desde JSON
get_wallpaper_from_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "Archivo de configuración no encontrado: $CONFIG_FILE"
        return 1
    fi
    
    # Extraer el wallpaper del JSON usando python o jq
    local wallpaper=""
    
    # Intentar con python primero (más compatible)
    if command -v python3 &> /dev/null; then
        wallpaper=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('current_wallpaper', ''))" 2>/dev/null)
    # Si no hay python, intentar con jq
    elif command -v jq &> /dev/null; then
        wallpaper=$(jq -r '.current_wallpaper // ""' "$CONFIG_FILE" 2>/dev/null)
    fi
    
    echo "$wallpaper"
}

# Función para obtener wallpaper por defecto
get_default_wallpaper() {
    local default_file=""
    
    # Buscar wallpaper por defecto en varias ubicaciones
    if [ -f "$DEFAULT_WALLPAPER" ]; then
        default_file="$DEFAULT_WALLPAPER"
    elif [ -f "$HOME/.config/wallpapers/default.png" ]; then
        default_file="$HOME/.config/wallpapers/default.png"
    elif [ -f "$HOME/.config/wallpapers/default.jpg" ]; then
        default_file="$HOME/.config/wallpapers/default.jpg"
    elif [ -f "/usr/share/backgrounds/default.png" ]; then
        default_file="/usr/share/backgrounds/default.png"
    fi
    
    echo "$default_file"
}

# Función para obtener un wallpaper aleatorio si se solicita
get_random_wallpaper() {
    local wallpapers_dir="$HOME/.config/wallpapers"
    
    if [ ! -d "$wallpapers_dir" ]; then
        return 1
    fi
    
    # Extensiones soportadas
    local extensions="*.png *.jpg *.jpeg *.PNG *.JPG *.JPEG *.webp *.mp4 *.webm *.mov"
    local wallpapers=()
    
    # Recopilar todos los wallpapers
    for ext in $extensions; do
        while IFS= read -r file; do
            [ -f "$file" ] && wallpapers+=("$file")
        done < <(find "$wallpapers_dir" -name "$ext" -type f 2>/dev/null)
    done
    
    if [ ${#wallpapers[@]} -gt 0 ]; then
        local random_index=$((RANDOM % ${#wallpapers[@]}))
        echo "${wallpapers[$random_index]}"
        return 0
    fi
    
    return 1
}

# Función principal
main() {
    log_message "Iniciando carga de wallpaper..."
    
    # Verificar wallset
    if ! check_wallset; then
        log_message "wallset no disponible, usando fallback con feh"
        
        # Fallback con feh si wallset no está disponible
        if command -v feh &> /dev/null; then
            local wallpaper=$(get_wallpaper_from_config)
            
            if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
                feh --bg-fill "$wallpaper"
                log_message "Wallpaper aplicado con feh (fallback): $wallpaper"
            else
                local default_wallpaper=$(get_default_wallpaper)
                if [ -n "$default_wallpaper" ]; then
                    feh --bg-fill "$default_wallpaper"
                    log_message "Wallpaper por defecto aplicado con feh: $default_wallpaper"
                fi
            fi
        else
            log_message "Error: ni wallset ni feh están disponibles"
            echo "Error: Instala wallset (pip install wallset) o feh para cambiar el wallpaper" >&2
        fi
        return
    fi
    
    # Modo aleatorio si se pasa el flag
    local random_mode=false
    if [ "$1" = "--random" ] || [ "$1" = "-r" ]; then
        random_mode=true
    fi
    
    local wallpaper=""
    
    # Si es modo aleatorio, seleccionar uno aleatorio
    if [ "$random_mode" = true ]; then
        wallpaper=$(get_random_wallpaper)
        if [ -n "$wallpaper" ]; then
            log_message "Modo aleatorio: seleccionado $wallpaper"
            # Guardar el wallpaper aleatorio en la configuración
            if command -v python3 &> /dev/null; then
                python3 -c "import json; config={'current_wallpaper': '$wallpaper'}; json.dump(config, open('$CONFIG_FILE', 'w'))" 2>/dev/null
                log_message "Wallpaper aleatorio guardado en configuración"
            fi
        fi
    fi
    
    # Si no se seleccionó aleatorio o falló, usar el guardado
    if [ -z "$wallpaper" ]; then
        wallpaper=$(get_wallpaper_from_config)
    fi
    
    # Si hay wallpaper configurado, aplicarlo
    if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
        log_message "Aplicando wallpaper configurado: $wallpaper"
        if apply_wallpaper "$wallpaper"; then
            echo "Wallpaper cargado: $wallpaper"
            return 0
        else
            log_message "Error al aplicar wallpaper configurado"
        fi
    fi
    
    # Si falla, intentar con wallpaper por defecto
    log_message "Intentando wallpaper por defecto"
    local default_wallpaper=$(get_default_wallpaper)
    if [ -n "$default_wallpaper" ]; then
        log_message "Aplicando wallpaper por defecto: $default_wallpaper"
        if apply_wallpaper "$default_wallpaper"; then
            echo "Wallpaper por defecto cargado: $default_wallpaper"
            return 0
        fi
    fi
    
    # Si todo falla, buscar cualquier wallpaper en el directorio
    log_message "Buscando cualquier wallpaper en el directorio"
    local any_wallpaper=$(get_random_wallpaper)
    if [ -n "$any_wallpaper" ]; then
        log_message "Aplicando wallpaper encontrado: $any_wallpaper"
        if apply_wallpaper "$any_wallpaper"; then
            echo "Wallpaper encontrado cargado: $any_wallpaper"
            return 0
        fi
    fi
    
    log_message "No se pudo cargar ningún wallpaper"
    echo "Error: No se pudo cargar ningún wallpaper" >&2
    return 1
}

# Ejecutar función principal con argumentos
main "$@"