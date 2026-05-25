#!/usr/bin/env python3
import sys
import shutil
import subprocess
from pathlib import Path

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, Pango

class StickerPicker(Gtk.Window):
    def __init__(self):
        super().__init__(title="Sticker Picker")
        
        # Floating window with fixed dimensions
        self.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU)
        self.set_default_size(400, 600)
        self.set_resizable(False)
        self.set_size_request(400, 600)
        self.set_keep_above(True)
        self.set_decorated(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        self.connect("key-press-event", self.on_key_press)
        
        # FOLDER
        self.stickers_dir = Path.home() / ".config" / "stickers"
        self.stickers_dir.mkdir(parents=True, exist_ok=True)
        
        self.supported_extensions = ('.png', '.jpg', '.jpeg', '.gif', 'webp')
        
        self.setup_ui()
        self.load_stickers()
        self.connect("destroy", Gtk.main_quit)
        self.show_all()
    
    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        return False
    
    def setup_ui(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(vbox)
        
        header_bar = Gtk.HeaderBar()
        header_bar.set_show_close_button(True)
        header_bar.set_title("Sticker Picker")
        self.set_titlebar(header_bar)
        
        add_button = Gtk.Button(label="+")
        add_button.connect("clicked", self.on_add_sticker)
        header_bar.pack_end(add_button)
        
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        vbox.pack_start(scrolled, True, True, 0)
        
        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_max_children_per_line(3)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.NONE)
        scrolled.add(self.flowbox)
    
    def create_empty_state_widget(self):
        """Create a beautiful empty state widget with visual appeal"""
        # Container box with vertical layout
        container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        container.set_valign(Gtk.Align.CENTER)
        container.set_halign(Gtk.Align.CENTER)
        container.set_margin_top(80)
        container.set_margin_bottom(80)
        container.set_margin_start(30)
        container.set_margin_end(30)
        
        # Emoji/sticker icon as a label (since it's simple and works everywhere)
        icon_label = Gtk.Label()
        icon_label.set_markup("<span size='80000'>🎨</span>")
        icon_label.set_valign(Gtk.Align.CENTER)
        icon_label.set_halign(Gtk.Align.CENTER)
        container.pack_start(icon_label, False, False, 0)
        
        # Main title
        title_label = Gtk.Label()
        title_label.set_markup("<span weight='bold' size='large'>No Stickers Yet</span>")
        title_label.set_justify(Gtk.Justification.CENTER)
        container.pack_start(title_label, False, False, 0)
        
        # Subtitle with instructions
        subtitle_label = Gtk.Label()
        subtitle_label.set_markup(
            "<span foreground='#888888'>Add some stickers to get started\n"
            "Click the <b>+</b> button in the top bar to add images</span>"
        )
        subtitle_label.set_justify(Gtk.Justification.CENTER)
        subtitle_label.set_line_wrap(True)
        subtitle_label.set_max_width_chars(30)
        container.pack_start(subtitle_label, False, False, 0)
        
        # Hint about supported formats
        hint_label = Gtk.Label()
        hint_label.set_markup(
            "<span foreground='#aaaaaa' size='small'>Supported: PNG, JPG, GIF, WebP</span>"
        )
        hint_label.set_justify(Gtk.Justification.CENTER)
        container.pack_start(hint_label, False, False, 0)
        
        # Add a subtle separator
        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        separator.set_margin_top(10)
        separator.set_size_request(150, -1)
        container.pack_start(separator, False, False, 0)
        
        # Quick tip
        tip_label = Gtk.Label()
        tip_label.set_markup(
            "<span foreground='#666666' size='small'>💡 Tip: Press ESC to close</span>"
        )
        tip_label.set_justify(Gtk.Justification.CENTER)
        container.pack_start(tip_label, False, False, 0)
        
        # Apply CSS styling for better visual appearance
        css_provider = Gtk.CssProvider()
        css = """
            .empty-state {
                background-color: alpha(currentColor, 0.02);
                border-radius: 12px;
                padding: 20px;
            }
        """
        css_provider.load_from_data(css.encode())
        context = container.get_style_context()
        context.add_class("empty-state")
        context.add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        container.show_all()
        return container
    
    def load_stickers(self):
        # Clear existing children
        for child in self.flowbox.get_children():
            child.destroy()
        
        # Collect all sticker files
        sticker_files = []
        for ext in self.supported_extensions:
            sticker_files.extend(self.stickers_dir.glob(f"*{ext}"))
            sticker_files.extend(self.stickers_dir.glob(f"*{ext.upper()}"))
        sticker_files.sort()
        
        # Show beautiful empty state if no stickers
        if not sticker_files:
            empty_widget = self.create_empty_state_widget()
            self.flowbox.add(empty_widget)
            return
        
        # Add all stickers
        for path in sticker_files:
            self.add_sticker_button(path)
    
    def add_sticker_button(self, sticker_path):
        event_box = Gtk.EventBox()
        event_box.connect("button-press-event", self.on_sticker_clicked, sticker_path)
        
        # Add hover effect with CSS
        css_provider = Gtk.CssProvider()
        css = """
            .sticker-button:hover {
                background-color: rgba(128, 128, 128, 0.1);
                border-radius: 8px;
            }
            .sticker-button {
                padding: 8px;
                transition: all 0.2s ease;
            }
        """
        css_provider.load_from_data(css.encode())
        context = event_box.get_style_context()
        context.add_class("sticker-button")
        context.add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(str(sticker_path), 100, 100)
            image = Gtk.Image.new_from_pixbuf(pixbuf)
        except Exception:
            image = Gtk.Image.new_from_icon_name("image-missing", Gtk.IconSize.DIALOG)
        
        event_box.add(image)
        event_box.set_tooltip_text(sticker_path.name)
        self.flowbox.add(event_box)
        event_box.show_all()
    
    def on_sticker_clicked(self, widget, event, sticker_path):
        if event.button == 1:
            self.copy_and_close(sticker_path)
    
    def copy_and_close(self, sticker_path):
        """Copies the sticker as a file URI (text/uri-list) and closes"""
        try:
            # Convert path to file URI
            file_uri = Path(sticker_path).resolve().as_uri()
            # Copy using wl-copy with text/uri-list type
            subprocess.run(['wl-copy', '-t', 'text/uri-list'], 
                           input=file_uri, 
                           encoding='utf-8', 
                           check=True)
        except Exception as e:
            print(f"Error copying: {e}")
        finally:
            Gtk.main_quit()
    
    def on_add_sticker(self, widget):
        dialog = Gtk.FileChooserDialog(
            title="Add Stickers",
            parent=self,
            action=Gtk.FileChooserAction.OPEN,
            buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                    Gtk.STOCK_OPEN, Gtk.ResponseType.OK)
        )
        dialog.set_select_multiple(True)
        
        filter_images = Gtk.FileFilter()
        filter_images.set_name("Image files")
        for ext in ['png', 'jpg', 'jpeg', 'gif', 'webp']:
            filter_images.add_pattern(f"*.{ext}")
            filter_images.add_pattern(f"*.{ext.upper()}")
        dialog.add_filter(filter_images)
        
        if dialog.run() == Gtk.ResponseType.OK:
            for file in dialog.get_files():
                src = file.get_path()
                dst = self.stickers_dir / Path(src).name
                try:
                    shutil.copy2(src, dst)
                except Exception as e:
                    print(f"Error copying: {e}")
            self.load_stickers()
        dialog.destroy()

def main():
    if shutil.which('wl-copy') is None:
        print("ERROR: wl-clipboard is required. Install with: sudo apt install wl-clipboard")
        sys.exit(1)
    
    app = StickerPicker()
    Gtk.main()

if __name__ == "__main__":
    main()