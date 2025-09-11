namespace Notejot {
    public class AddTagDialog : He.Window {
        public signal void response(int response_id);

        public He.TextField name_entry { get; private set; }
        private Gtk.Label title_label;
        private Gtk.MenuButton color_button;
        private Gtk.FlowBox icon_grid;
        private Gtk.Widget? overlay_image = null;

        private string? selected_icon_name = "tag-symbolic";
        private string? selected_color;

        private string[] icon_names = {
            "tag-symbolic", "user-bookmarks-symbolic", "folder-symbolic",
            "emblem-documents-symbolic", "emblem-favorite-symbolic",
            "emblem-important-symbolic", "emblem-photos-symbolic", "emoji-travel-symbolic",
            "weather-clear-night-symbolic", "weather-clear-symbolic",
            "globe-symbolic", "bookmark-new-symbolic", "emoji-love-symbolic",
            "network-server-symbolic", "mail-read-symbolic",
            "emoji-food-symbolic", "airplane-mode-symbolic",
            "calendar-symbolic", "document-new-symbolic",
            "system-search-symbolic"
        };

        // Standard Color Palette
        private string[] color_palette = {
            "#e57373",
            "#ffb74d",
            "#ffd54f",
            "#81c784",
            "#4db6ac",
            "#4dd0e1",
            "#32ade6",
            "#64b5f6",
            "#7986cb",
            "#ba68c8",
            "#f06292",
            "#bcaaa4"
        };

        public AddTagDialog(Gtk.Window parent, bool editing = false) {
            Object(
                   parent : parent,
                   default_width: 440,
                   resizable: false
            );

            add_css_class("dialog-content");

            // Header with close button
            var header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            header_box.set_margin_top(12);
            header_box.set_margin_start(12);
            header_box.set_margin_end(12);
            header_box.set_margin_bottom(12);

            title_label = new Gtk.Label(editing == true ? _("Edit Tag") : _("Add Tag"));
            title_label.add_css_class("title-3");
            header_box.append(title_label);

            header_box.append(new Gtk.Label("") { hexpand = true }); // Spacer

            var close_button = new He.Button("window-close-symbolic", "");
            close_button.is_disclosure = true;
            close_button.clicked.connect(() => {
                response(Gtk.ResponseType.CANCEL);
                this.close();
            });
            header_box.append(close_button);

            var winhandle = new Gtk.WindowHandle();
            winhandle.set_child(header_box);

            // --- Main ---
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            main_box.set_margin_top(6);
            main_box.set_margin_bottom(12);
            main_box.set_margin_start(12);
            main_box.set_margin_end(12);

            // Preview
            var preview_overlay = new Gtk.Overlay();
            preview_overlay.set_size_request(64, 64);
            preview_overlay.set_halign(Gtk.Align.CENTER);
            preview_overlay.set_valign(Gtk.Align.CENTER);
            var preview_color = new Gtk.DrawingArea();
            preview_color.set_content_width(64);
            preview_color.set_content_height(64);
            preview_color.set_draw_func((area, cr, w, h) => {
                var rgba = Gdk.RGBA();
                rgba.parse(this.selected_color == null ? "#ffd54f" : this.selected_color);
                cr.set_source_rgba(rgba.red, rgba.green, rgba.blue, rgba.alpha);
                cr.arc(w / 2.0, h / 2.0, w / 2.0, 0, 2 * Math.PI);
                cr.fill();
            });
            preview_overlay.set_child(preview_color);

            var image = new Gtk.Image.from_icon_name(selected_icon_name) {
                pixel_size = 32,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                css_classes = { "inverted-icon" }
            };
            // Remove previous overlay image if present
            if (this.overlay_image != null) {
                preview_overlay.remove_overlay(this.overlay_image);
                this.overlay_image = null;
            }
            preview_overlay.add_overlay(image);
            this.overlay_image = image;

            var preview_label = new Gtk.Label("");
            preview_label.set_halign(Gtk.Align.CENTER);
            preview_label.set_valign(Gtk.Align.CENTER);
            preview_label.add_css_class("dim-label");

            var preview_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            preview_box.set_halign(Gtk.Align.CENTER);
            preview_box.set_valign(Gtk.Align.CENTER);
            preview_box.margin_bottom = 12;
            preview_box.append(preview_overlay);
            preview_box.append(preview_label);
            main_box.append(preview_box);

            // Name + Color row
            var name_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            this.name_entry = new He.TextField() { placeholder_text = _("Tag Name"), hexpand = true, is_outline = true };
            name_row.append(this.name_entry);

            preview_label.label = _("Tag Name");
            this.name_entry.get_internal_entry().changed.connect(() => {
                preview_label.label = this.name_entry.get_internal_entry().text != "" ? this.name_entry.get_internal_entry().text : _("Tag Name");
            });

            this.color_button = new Gtk.MenuButton();
            this.color_button.set_tooltip_text(_("Select Color"));
            this.color_button.set_size_request(32, 32);
            this.color_button.set_halign(Gtk.Align.CENTER);
            this.color_button.set_valign(Gtk.Align.CENTER);
            this.color_button.get_first_child().add_css_class("fill-button");
            this.color_button.get_first_child().add_css_class("circular");
            var color_area = new Gtk.DrawingArea();
            color_area.set_halign(Gtk.Align.CENTER);
            color_area.set_valign(Gtk.Align.CENTER);
            color_area.set_content_width(24);
            color_area.set_content_height(24);
            color_area.set_draw_func((a, cr, w, h) => {
                var rgba = Gdk.RGBA();
                rgba.parse(this.selected_color == null ? "#ffd54f" : this.selected_color);
                cr.set_source_rgba(rgba.red, rgba.green, rgba.blue, rgba.alpha);
                cr.arc(w / 2.0, h / 2.0, w / 2.0, 0, 2 * Math.PI);
                cr.fill();
            });
            this.color_button.set_child(color_area);
            name_row.append(this.color_button);
            main_box.append(name_row);

            // Color popover
            var color_popover = new Gtk.Popover();
            this.color_button.set_popover(color_popover);
            var color_flow = new Gtk.FlowBox();
            color_flow.set_selection_mode(Gtk.SelectionMode.NONE);
            color_flow.set_max_children_per_line(6);
            color_popover.set_child(color_flow);

            foreach (var c in this.color_palette) {
                var btn = new Gtk.Button();
                var swatch = new Gtk.DrawingArea();
                swatch.set_content_width(32);
                swatch.set_content_height(32);
                var current_color = c;
                swatch.set_draw_func((a, cr, w, h) => {
                    var rgba = Gdk.RGBA();
                    rgba.parse(current_color);
                    cr.set_source_rgba(rgba.red, rgba.green, rgba.blue, rgba.alpha);
                    cr.arc(w / 2.0, h / 2.0, w / 2.0, 0, 2 * Math.PI);
                    cr.fill();
                });
                btn.set_child(swatch);
                btn.add_css_class("flat");
                btn.clicked.connect((btn) => {
                    // Use the color from the swatch's draw_func closure, not a possibly mutated loop variable
                    var swatch_color = current_color;
                    this.selected_color = swatch_color;
                    color_area.queue_draw();
                    preview_color.queue_draw();
                    color_popover.popdown();
                });
                color_flow.insert(btn, -1);
            }

            // Icon grid (4x5)
            this.icon_grid = new Gtk.FlowBox();
            this.icon_grid.set_selection_mode(Gtk.SelectionMode.NONE);
            this.icon_grid.set_max_children_per_line(5);
            this.icon_grid.set_min_children_per_line(4);
            foreach (var icon_name in this.icon_names) {
                var btn = new Gtk.Button.from_icon_name(icon_name);
                btn.add_css_class("tint-button");
                btn.add_css_class("circular");
                btn.set_halign(Gtk.Align.CENTER);
                btn.set_valign(Gtk.Align.CENTER);
                btn.set_tooltip_text(icon_name);
                btn.clicked.connect(() => {
                    this.selected_icon_name = icon_name;
                    var simage = new Gtk.Image.from_icon_name(icon_name) {
                        pixel_size = 32,
                        halign = Gtk.Align.CENTER,
                        valign = Gtk.Align.CENTER,
                        css_classes = { "inverted-icon" }
                    };
                    // Remove previous overlay image if present
                    if (this.overlay_image != null) {
                        preview_overlay.remove_overlay(this.overlay_image);
                        this.overlay_image = null;
                    }
                    preview_overlay.add_overlay(simage);
                    this.overlay_image = simage;
                });
                this.icon_grid.insert(btn, -1);
            }
            main_box.append(this.icon_grid);

            // Bottom buttons
            var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            button_box.set_halign(Gtk.Align.END);
            button_box.set_margin_top(12);
            button_box.set_margin_bottom(12);
            button_box.set_margin_start(12);
            button_box.set_margin_end(12);
            main_box.append(button_box);

            var cancel_button = new He.Button("", _("Cancel"));
            cancel_button.is_tint = true;
            cancel_button.clicked.connect(() => {
                response(Gtk.ResponseType.CANCEL);
                this.close();
            });
            button_box.append(cancel_button);

            var save_button = new He.Button("", _("Save"));
            save_button.is_fill = true;
            save_button.clicked.connect(() => {
                response(Gtk.ResponseType.ACCEPT);
                this.close();
            });
            button_box.append(save_button);

            // Pack everything
            var container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            container.append(winhandle);
            container.append(main_box);
            this.set_child(container);
        }

        public string ? get_selected_icon_name() {
            return this.selected_icon_name;
        }

        public string get_selected_color() {
            return this.selected_color;
        }

        public void set_selected_color(string color) {
            this.selected_color = color;
            var da = this.color_button.get_child() as Gtk.DrawingArea;
            if (da != null) {
                da.queue_draw();
            }
        }

        public void set_selected_icon_name(string? icon_name) {
            this.selected_icon_name = icon_name;
            var preview_overlay = (this.icon_grid.get_parent() as Gtk.Box) ? .get_first_child() as Gtk.Overlay;
            // Remove previous overlay image if present
            if (this.overlay_image != null) {
                preview_overlay.remove_overlay(this.overlay_image);
                this.overlay_image = null;
            }
            if (icon_name != null) {
                var image = new Gtk.Image.from_icon_name(icon_name) {
                    pixel_size = 32,
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                    css_classes = { "inverted-icon" }
                };
                preview_overlay.add_overlay(image);
                this.overlay_image = image;
            }
        }

        public void prefill(string name, string color, string? icon_name) {
            this.name_entry.get_internal_entry().text = name;
            this.set_selected_color(color);
            this.set_selected_icon_name(icon_name);
        }
    }
}
