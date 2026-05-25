#!/usr/bin/env python3
"""
Wallpaper Selector - Versión GTK3 con soporte para videos (wallset)
Respeta el tema GTK del sistema
"""

import os
import sys
import subprocess
import json
from pathlib import Path
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib

class WallpaperSelectorGTK:
    def __init__(self):
        # Directorio de wallpapers
        self.wallpapers_dir = Path.home() / ".config/wallpapers"
        self.config_file = Path.home() / ".config/wallpaper_config.json"
        
        # Crear directorio si no existe
        self.wallpapers_dir.mkdir(parents=True, exist_ok=True)
        
        # Verificar que wallset esté instalado
        self.check_wallset()
        
        # Cargar configuración guardada
        self.current_wallpaper = self.load_config()
        
        # Configurar la ventana
        self.window = Gtk.Window()
        self.window.set_title("Wallpaper Selector")
        self.window.set_default_size(500, 600)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_border_width(0)
        
        # Configurar como ventana flotante
        self.window.set_type_hint(Gdk.WindowTypeHint.DIALOG)
        self.window.set_modal(False)
        
        # Crear UI
        self.setup_ui()
        
        # Cargar wallpapers
        self.load_wallpapers()
        
        # Mostrar ventana
        self.window.show_all()
    
    def check_wallset(self):
        """Verificar que wallset esté instalado"""
        try:
            subprocess.run(["wallset", "--version"], 
                         capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            # Mostrar advertencia pero continuar
            print("Advertencia: wallset no está instalado")
            print("Instálalo con: pip install wallset")
    
    def setup_ui(self):
        """Configurar la interfaz de usuario"""
        # VBox principal
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.window.add(vbox)
        
        # Frame superior con título
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        title_box.set_border_width(10)
        vbox.pack_start(title_box, False, False, 0)
        
        # Título
        title_label = Gtk.Label()
        title_label.set_markup("<big><b>Wallpaper Selector</b></big>")
        title_label.set_halign(Gtk.Align.START)
        title_box.pack_start(title_label, True, True, 0)
        
        # Separador
        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        vbox.pack_start(separator, False, False, 0)
        
        # Barra de herramientas
        toolbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        toolbar.set_border_width(10)
        vbox.pack_start(toolbar, False, False, 0)
        
        # Botón recargar
        reload_btn = Gtk.Button.new_from_icon_name("view-refresh", Gtk.IconSize.BUTTON)
        reload_btn.set_tooltip_text("Recargar wallpapers")
        reload_btn.connect("clicked", self.on_reload_clicked)
        toolbar.pack_start(reload_btn, False, False, 0)
        
        # Botón abrir carpeta
        folder_btn = Gtk.Button.new_from_icon_name("folder-open", Gtk.IconSize.BUTTON)
        folder_btn.set_tooltip_text("Abrir carpeta de wallpapers")
        folder_btn.connect("clicked", self.on_open_folder_clicked)
        toolbar.pack_start(folder_btn, False, False, 0)
        
        # Separador
        sep = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
        toolbar.pack_start(sep, False, False, 5)
        
        # Filtro de tipo de archivo
        filter_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        toolbar.pack_start(filter_box, True, True, 0)
        
        filter_label = Gtk.Label()
        filter_label.set_text("Mostrar:")
        filter_box.pack_start(filter_label, False, False, 0)
        
        self.filter_combo = Gtk.ComboBoxText()
        self.filter_combo.append_text("Todos")
        self.filter_combo.append_text("Imágenes")
        self.filter_combo.append_text("Videos")
        self.filter_combo.set_active(0)
        self.filter_combo.connect("changed", self.on_filter_changed)
        filter_box.pack_start(self.filter_combo, False, False, 0)
        
        # Label con wallpaper actual
        current_frame = Gtk.Frame()
        current_frame.set_shadow_type(Gtk.ShadowType.NONE)
        toolbar.pack_start(current_frame, True, True, 0)
        
        current_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        current_frame.add(current_box)
        
        current_icon = Gtk.Image.new_from_icon_name("image-x-generic", Gtk.IconSize.MENU)
        current_box.pack_start(current_icon, False, False, 0)
        
        if self.current_wallpaper:
            current_text = f"Actual: {os.path.basename(self.current_wallpaper)}"
        else:
            current_text = "Actual: Ninguno"
        
        self.current_label = Gtk.Label()
        self.current_label.set_text(current_text)
        self.current_label.set_halign(Gtk.Align.START)
        current_box.pack_start(self.current_label, True, True, 0)
        
        # Botón aplicar
        apply_btn = Gtk.Button.new_with_label("Aplicar")
        apply_btn.connect("clicked", self.on_apply_clicked)
        toolbar.pack_end(apply_btn, False, False, 0)
        
        # ScrolledWindow para thumbnails
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.IN)
        vbox.pack_start(scrolled, True, True, 0)
        
        # FlowBox para thumbnails
        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_selection_mode(Gtk.SelectionMode.NONE)
        self.flowbox.set_max_children_per_line(2)
        self.flowbox.set_column_spacing(10)
        self.flowbox.set_row_spacing(10)
        self.flowbox.set_homogeneous(True)
        scrolled.add(self.flowbox)
        
        # Barra de estado
        self.statusbar = Gtk.Statusbar()
        self.status_context = self.statusbar.get_context_id("status")
        self.statusbar.push(self.status_context, "Listo")
        vbox.pack_end(self.statusbar, False, False, 0)
    
    def get_supported_extensions(self, file_type="all"):
        """Obtener extensiones soportadas según el filtro"""
        images = ['*.png', '*.jpg', '*.jpeg', '*.PNG', '*.JPG', '*.JPEG', '*.webp', '*.bmp', '*.gif']
        videos = ['*.mp4', '*.webm', '*.mov', '*.avi', '*.mkv', '*.gif']  # gif puede ser tratado como video
        
        if file_type == "images":
            return images
        elif file_type == "videos":
            return videos
        else:
            return images + videos
    
    def load_wallpapers(self):
        """Cargar todos los wallpapers del directorio según el filtro"""
        # Limpiar FlowBox
        for child in self.flowbox.get_children():
            self.flowbox.remove(child)
        
        # Obtener filtro actual
        filter_text = self.filter_combo.get_active_text()
        if filter_text == "Imágenes":
            file_type = "images"
        elif filter_text == "Videos":
            file_type = "videos"
        else:
            file_type = "all"
        
        # Buscar archivos
        extensions = self.get_supported_extensions(file_type)
        wallpapers = []
        
        for ext in extensions:
            wallpapers.extend(self.wallpapers_dir.glob(ext))
        
        if not wallpapers:
            self.show_no_wallpapers(file_type)
            return
        
        # Ordenar por nombre
        wallpapers.sort()
        
        # Crear thumbnails
        for wallpaper in wallpapers:
            self.create_thumbnail(wallpaper)
        
        count = len(wallpapers)
        self.update_status(f"{count} {'wallpapers' if file_type == 'all' else file_type} cargados")
    
    def create_thumbnail(self, image_path):
        """Crear thumbnail para una imagen o video"""
        try:
            # Crear contenedor con sombra
            frame = Gtk.Frame()
            frame.set_shadow_type(Gtk.ShadowType.ETCHED_IN)
            frame.set_size_request(220, 210)
            
            container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
            container.set_border_width(8)
            frame.add(container)
            
            # Detectar si es video por extensión
            video_extensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv']
            is_video = image_path.suffix.lower() in video_extensions
            
            # Crear imagen o icono según el tipo
            if is_video:
                # Para videos, mostrar icono de video
                video_icon = Gtk.Image.new_from_icon_name("video-x-generic", Gtk.IconSize.DIALOG)
                video_icon.set_pixel_size(120)
                container.pack_start(video_icon, False, False, 0)
                
                # Intentar obtener thumbnail del video (si es posible)
                self.create_video_thumbnail_async(image_path, container)
            else:
                # Para imágenes, cargar thumbnail
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(str(image_path))
                
                # Redimensionar manteniendo aspecto
                target_width = 200
                target_height = 150
                width = pixbuf.get_width()
                height = pixbuf.get_height()
                
                # Calcular escalado
                if width > height:
                    scale = target_width / width
                else:
                    scale = target_height / height
                
                new_width = int(width * scale)
                new_height = int(height * scale)
                
                # Escalar imagen
                scaled_pixbuf = pixbuf.scale_simple(
                    new_width, new_height,
                    GdkPixbuf.InterpType.BILINEAR
                )
                
                # Crear Image
                image = Gtk.Image.new_from_pixbuf(scaled_pixbuf)
                container.pack_start(image, False, False, 0)
            
            # Nombre del archivo
            name = image_path.stem
            if len(name) > 25:
                name = name[:22] + "..."
            
            name_label = Gtk.Label()
            name_label.set_text(name)
            name_label.set_halign(Gtk.Align.CENTER)
            name_label.set_tooltip_text(image_path.name)
            container.pack_start(name_label, False, False, 0)
            
            # Tipo de archivo (imagen/video)
            type_label = Gtk.Label()
            if is_video:
                type_label.set_markup("<small><i>🎬 Video</i></small>")
            else:
                type_label.set_markup("<small><i>🖼️ Imagen</i></small>")
            type_label.set_halign(Gtk.Align.CENTER)
            container.pack_start(type_label, False, False, 0)
            
            # Botón seleccionar
            select_btn = Gtk.Button.new_with_label("Seleccionar")
            select_btn.connect("clicked", self.on_select_clicked, image_path)
            container.pack_start(select_btn, False, False, 0)
            
            # Resaltar si es el actual
            if self.current_wallpaper and str(image_path) == self.current_wallpaper:
                select_btn.get_style_context().add_class("suggested-action")
                frame.set_tooltip_text("Wallpaper actual")
            
            # Añadir al FlowBox
            self.flowbox.add(frame)
            
        except Exception as e:
            print(f"Error al crear thumbnail para {image_path}: {e}")
            self.create_error_thumbnail(image_path)
    
    def create_video_thumbnail_async(self, video_path, container):
        """Crear thumbnail de video de forma asíncrona usando ffmpegthumbnailer"""
        try:
            # Verificar si ffmpegthumbnailer está instalado
            thumbnail_path = Path(f"/tmp/video_thumb_{video_path.stem}.jpg")
            
            if not thumbnail_path.exists():
                # Generar thumbnail con ffmpegthumbnailer
                subprocess.run([
                    "ffmpegthumbnailer", "-i", str(video_path),
                    "-o", str(thumbnail_path), "-s", "200", "-c", "jpg", "-t", "00:00:01"
                ], capture_output=True, timeout=5)
            
            if thumbnail_path.exists():
                # Cargar thumbnail generado
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(str(thumbnail_path))
                pixbuf = pixbuf.scale_simple(200, 150, GdkPixbuf.InterpType.BILINEAR)
                image = Gtk.Image.new_from_pixbuf(pixbuf)
                
                # Reemplazar el icono de video con el thumbnail
                # Nota: Esto es simplificado, en producción necesitarías
                # remover el icono existente y añadir la imagen
                for child in container.get_children():
                    if isinstance(child, Gtk.Image) and child != container.get_children()[-1]:
                        container.remove(child)
                        container.pack_start(image, False, False, 0)
                        container.reorder_child(image, 0)
                        break
        except Exception as e:
            print(f"Error generando thumbnail de video: {e}")
    
    def create_error_thumbnail(self, image_path):
        """Crear thumbnail de error para archivos corruptos"""
        frame = Gtk.Frame()
        frame.set_shadow_type(Gtk.ShadowType.ETCHED_IN)
        frame.set_size_request(220, 210)
        
        container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        container.set_border_width(8)
        frame.add(container)
        
        # Icono de error
        error_icon = Gtk.Image.new_from_icon_name("image-missing", Gtk.IconSize.DIALOG)
        container.pack_start(error_icon, False, False, 0)
        
        # Nombre del archivo
        name = image_path.stem
        if len(name) > 25:
            name = name[:22] + "..."
        
        name_label = Gtk.Label()
        name_label.set_text(name)
        name_label.set_halign(Gtk.Align.CENTER)
        container.pack_start(name_label, False, False, 0)
        
        error_label = Gtk.Label()
        error_label.set_markup("<small>Error al cargar</small>")
        error_label.set_halign(Gtk.Align.CENTER)
        container.pack_start(error_label, False, False, 0)
        
        self.flowbox.add(frame)
    
    def show_no_wallpapers(self, file_type):
        """Mostrar mensaje cuando no hay wallpapers"""
        frame = Gtk.Frame()
        frame.set_shadow_type(Gtk.ShadowType.NONE)
        
        container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        container.set_border_width(50)
        container.set_halign(Gtk.Align.CENTER)
        container.set_valign(Gtk.Align.CENTER)
        frame.add(container)
        
        # Icono según el tipo
        if file_type == "images":
            icon_name = "image-x-generic"
            msg_type = "imágenes"
        elif file_type == "videos":
            icon_name = "video-x-generic"
            msg_type = "videos"
        else:
            icon_name = "folder"
            msg_type = "wallpapers"
        
        icon = Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.DIALOG)
        container.pack_start(icon, False, False, 0)
        
        # Mensaje
        message = Gtk.Label()
        message.set_markup(f"<big>No se encontraron {msg_type}</big>\n\nAgrega archivos en:\n<i>~/.config/wallpapers/</i>")
        message.set_justify(Gtk.Justification.CENTER)
        container.pack_start(message, False, False, 0)
        
        # Botón abrir carpeta
        open_btn = Gtk.Button.new_with_label("Abrir carpeta")
        open_btn.connect("clicked", self.on_open_folder_clicked)
        container.pack_start(open_btn, False, False, 0)
        
        self.flowbox.add(frame)
        self.update_status(f"No se encontraron {msg_type}")
    
    def on_filter_changed(self, combo):
        """Cambiar filtro de tipo de archivo"""
        self.load_wallpapers()
    
    def on_select_clicked(self, button, file_path):
        """Seleccionar un wallpaper"""
        self.current_wallpaper = str(file_path)
        self.save_config()
        
        # Actualizar label
        self.current_label.set_text(f"Actual: {file_path.name}")
        self.update_status(f"Seleccionado: {file_path.name}")
        
        # Aplicar inmediatamente
        self.apply_wallpaper(file_path)
        
        # Recargar para actualizar el resaltado
        self.load_wallpapers()
    
    def on_apply_clicked(self, button):
        """Aplicar el wallpaper seleccionado"""
        if self.current_wallpaper and os.path.exists(self.current_wallpaper):
            self.apply_wallpaper(Path(self.current_wallpaper))
            
            # Mostrar diálogo de éxito
            dialog = Gtk.MessageDialog(
                transient_for=self.window,
                flags=0,
                message_type=Gtk.MessageType.INFO,
                buttons=Gtk.ButtonsType.OK,
                text="Wallpaper aplicado correctamente"
            )
            dialog.format_secondary_text(
                "Se guardará para la próxima sesión."
            )
            dialog.run()
            dialog.destroy()
        else:
            # Mostrar diálogo de advertencia
            dialog = Gtk.MessageDialog(
                transient_for=self.window,
                flags=0,
                message_type=Gtk.MessageType.WARNING,
                buttons=Gtk.ButtonsType.OK,
                text="No hay ningún wallpaper seleccionado"
            )
            dialog.run()
            dialog.destroy()
    
    def apply_wallpaper(self, file_path):
        """Aplicar wallpaper usando wallset (soporta imágenes y videos)"""
        try:
            # Detectar si es video por extensión
            video_extensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv']
            is_video = file_path.suffix.lower() in video_extensions
            
            if is_video:
                # Para videos, usar wallset con opción de video
                subprocess.run(
                    ["wallset", "--video", str(file_path)],
                    check=True
                )
                self.update_status(f"✓ Video wallpaper aplicado: {file_path.name}")
            else:
                # Para imágenes, usar wallset normal
                subprocess.run(
                    ["wallset", "--img", str(file_path)],
                    check=True
                )
                self.update_status(f"✓ Wallpaper aplicado: {file_path.name}")
                
        except subprocess.CalledProcessError as e:
            self.update_status(f"✗ Error al aplicar wallpaper")
            print(f"Error: {e}")
            
            # Mostrar diálogo de error con información
            dialog = Gtk.MessageDialog(
                transient_for=self.window,
                flags=0,
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.OK,
                text="Error al aplicar wallpaper"
            )
            dialog.format_secondary_text(
                f"Error: {e}\n\n"
                "Asegúrate de que wallset esté instalado:\n"
                "pip install wallset\n\n"
                "Para videos, también necesitas:\n"
                "- mpv (para reproducción)\n"
                "- ffmpegthumbnailer (para thumbnails)"
            )
            dialog.run()
            dialog.destroy()
            
        except FileNotFoundError:
            self.update_status("✗ wallset no está instalado")
            
            # Mostrar diálogo de instalación
            dialog = Gtk.MessageDialog(
                transient_for=self.window,
                flags=0,
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.OK,
                text="wallset no está instalado"
            )
            dialog.format_secondary_text(
                "Instala wallset para cambiar wallpapers:\n"
                "pip install wallset\n\n"
                "Para videos, también necesitas:\n"
                "sudo apt install mpv ffmpegthumbnailer  # Debian/Ubuntu\n"
                "sudo pacman -S mpv ffmpegthumbnailer    # Arch Linux"
            )
            dialog.run()
            dialog.destroy()
    
    def on_reload_clicked(self, button):
        """Recargar lista de wallpapers"""
        self.load_wallpapers()
        self.update_status("Lista recargada")
    
    def on_open_folder_clicked(self, button):
        """Abrir la carpeta de wallpapers en el explorador de archivos"""
        try:
            subprocess.Popen(["xdg-open", str(self.wallpapers_dir)])
            self.update_status(f"Abriendo {self.wallpapers_dir}")
        except Exception as e:
            print(f"Error al abrir carpeta: {e}")
    
    def load_config(self):
        """Cargar configuración guardada"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    wallpaper = config.get('current_wallpaper', '')
                    if wallpaper and os.path.exists(wallpaper):
                        return wallpaper
            except Exception as e:
                print(f"Error al cargar configuración: {e}")
        return None
    
    def save_config(self):
        """Guardar configuración"""
        config = {
            'current_wallpaper': self.current_wallpaper
        }
        try:
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            print(f"Error al guardar configuración: {e}")
    
    def update_status(self, message):
        """Actualizar barra de estado"""
        self.statusbar.push(self.status_context, message)
        # Auto-limpiar después de 3 segundos
        GLib.timeout_add_seconds(3, self.clear_status)
        return False
    
    def clear_status(self):
        """Limpiar barra de estado"""
        self.statusbar.push(self.status_context, "Listo")
        return False

def main():
    app = WallpaperSelectorGTK()
    Gtk.main()

if __name__ == "__main__":
    main()