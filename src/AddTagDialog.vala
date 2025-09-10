namespace Notejot {
    public class AddTagDialog : He.Window {
        public signal void response (int response_id);

        public He.TextField name_entry { get; private set; }
        private Gtk.MenuButton icon_button;
        private Gtk.MenuButton color_swatch_button;

        private string? selected_icon_name = null;
        private string selected_color = "#ffd54f"; // Yellow as default

        private string[] icon_names = {
            "tag-symbolic", "user-bookmarks-symbolic", "folder-symbolic",
            "emblem-documents-symbolic", "emblem-favorite-symbolic",
            "emblem-important-symbolic", "emblem-photos-symbolic", "emblem-shared-symbolic",
            "weather-clear-night-symbolic", "weather-clear-symbolic"
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

        public AddTagDialog(Gtk.Window parent) {
            Object(
                parent: parent,
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

            var title_label = new Gtk.Label(_("Add New Tag"));
            title_label.add_css_class("title-3");
            header_box.append(title_label);

            header_box.append(new Gtk.Label("") { hexpand = true }); // Spacer

            var close_button = new He.Button ("window-close-symbolic", "");
            close_button.is_disclosure = true;
            close_button.clicked.connect(() => {
                response(Gtk.ResponseType.CANCEL);
                this.close();
            });
            header_box.append(close_button);

            var winhandle = new Gtk.WindowHandle ();
            winhandle.set_child (header_box);

            // Main content area
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 15);
            main_box.set_margin_top(6);
            main_box.set_margin_bottom(12);
            main_box.set_margin_start(12);
            main_box.set_margin_end(12);

            // Name entry card
            var name_card = new Gtk.Frame(_("Name"));
            name_card.add_css_class("card");
            name_card.set_margin_bottom(6);
            var name_card_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            name_card_box.set_margin_top(12);
            name_card_box.set_margin_bottom(12);
            name_card_box.set_margin_start(12);
            name_card_box.set_margin_end(12);

            this.name_entry = new He.TextField();
            this.name_entry.placeholder_text = _("Tag Name");
            name_card_box.append(this.name_entry);

            name_card.set_child(name_card_box);
            main_box.append(name_card);

            // Color card
            var color_card = new Gtk.Frame(_("Color"));
            color_card.add_css_class("card");
            color_card.set_margin_bottom(6);
            var color_card_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            color_card_box.set_margin_top(12);
            color_card_box.set_margin_bottom(12);
            color_card_box.set_margin_start(12);
            color_card_box.set_margin_end(12);

            // Description for color selection
            var color_desc = new Gtk.Label(_("Choose a color for the tag"));
            color_desc.set_halign(Gtk.Align.START);
            color_desc.set_valign(Gtk.Align.CENTER);
            color_desc.set_hexpand(true);
            color_card_box.append(color_desc);

            // --- Color Popover Button ---
            this.color_swatch_button = new Gtk.MenuButton();
            this.color_swatch_button.get_first_child ().add_css_class ("tint-button");
            this.color_swatch_button.get_first_child ().add_css_class ("circular");
            this.color_swatch_button.set_halign(Gtk.Align.END);
            this.color_swatch_button.set_hexpand(true);
            this.color_swatch_button.set_tooltip_text(_("Click to choose a color"));
            var color_swatch_drawing_area = new Gtk.DrawingArea();
            color_swatch_drawing_area.set_content_width(24);
            color_swatch_drawing_area.set_content_height(24);
            color_swatch_drawing_area.set_draw_func(this.draw_color_swatch);
            this.color_swatch_button.set_child(color_swatch_drawing_area);
            color_card_box.append(this.color_swatch_button);

            var color_popover = new Gtk.Popover();
            this.color_swatch_button.set_popover(color_popover);

            var color_flow_box = new Gtk.FlowBox();
            color_flow_box.set_selection_mode(Gtk.SelectionMode.NONE);
            color_flow_box.set_max_children_per_line(6); // Adjusted for a 12-color grid
            color_flow_box.set_valign(Gtk.Align.START);
            color_popover.set_child(color_flow_box);

            foreach (var color in this.color_palette) {
                var color_button = new Gtk.Button();
                var swatch_area = new Gtk.DrawingArea();
                swatch_area.set_content_width(32);
                swatch_area.set_content_height(32);
                // Use a local variable for the color in the closure
                var current_color = color;
                color_button.set_tooltip_text(current_color);
                swatch_area.set_draw_func((area, cr, width, height) => {
                    var rgba = Gdk.RGBA();
                    rgba.parse(current_color);
                    cr.set_source_rgba(rgba.red, rgba.green, rgba.blue, rgba.alpha);
                    cr.arc(width/2.0, height/2.0, width/2.0, 0, 2 * Math.PI);
                    cr.fill();

                    // If this swatch is the selected color, draw an outline
                    if (current_color == this.selected_color) {
                        // Pick contrasting outline (white for dark colors, black for light)
                        double luminance = 0.2126 * rgba.red + 0.7152 * rgba.green + 0.0722 * rgba.blue;
                        if (luminance > 0.5) {
                            cr.set_source_rgba(0.0, 0.0, 0.0, 1.0);
                        } else {
                            cr.set_source_rgba(1.0, 1.0, 1.0, 1.0);
                        }
                        cr.set_line_width(2.0);
                        cr.arc(width/2.0, height/2.0, width/2.0 - 1.0, 0, 2 * Math.PI);
                        cr.stroke();
                    }
                });
                color_button.set_child(swatch_area);
                color_button.add_css_class ("flat");
                color_button.clicked.connect(() => {
                    this.selected_color = current_color;
                    var da = this.color_swatch_button.get_child() as Gtk.DrawingArea;
                    if (da != null) {
                        da.queue_draw();
                    }
                    color_popover.popdown();
                });
                color_flow_box.insert(color_button, -1);
            }

            color_card.set_child(color_card_box);
            main_box.append(color_card);

            // Icon card
            var icon_card = new Gtk.Frame(_("Icon"));
            icon_card.add_css_class("card");
            icon_card.set_margin_bottom(6);
            var icon_card_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            icon_card_box.set_margin_top(12);
            icon_card_box.set_margin_bottom(12);
            icon_card_box.set_margin_start(12);
            icon_card_box.set_margin_end(12);

            // Description for icon selection
            var icon_desc = new Gtk.Label(_("Pick an icon to represent the tag"));
            icon_desc.set_halign(Gtk.Align.START);
            icon_desc.set_valign(Gtk.Align.CENTER);
            icon_desc.set_hexpand(true);
            icon_card_box.append(icon_desc);

            // --- Icon Popover Button ---
            this.icon_button = new Gtk.MenuButton ();
            this.icon_button.get_first_child ().add_css_class ("tint-button");
            this.icon_button.get_first_child ().add_css_class ("circular");
            this.icon_button.set_icon_name("emblem-system-symbolic");
            this.icon_button.set_halign(Gtk.Align.END);
            this.icon_button.set_hexpand(true);
            this.icon_button.set_tooltip_text(_("Click to choose an icon"));
            icon_card_box.append(this.icon_button);

            var icon_popover = new Gtk.Popover();
            this.icon_button.set_popover(icon_popover);

            var icon_flow_box = new Gtk.FlowBox();
            icon_flow_box.set_selection_mode(Gtk.SelectionMode.NONE);
            icon_flow_box.set_max_children_per_line(5);
            icon_popover.set_child(icon_flow_box);

            foreach(var icon_name in this.icon_names) {
                var button = new Gtk.Button.from_icon_name(icon_name);
                button.set_tooltip_text(icon_name);
                button.add_css_class ("flat");
                button.clicked.connect(() => {
                    this.selected_icon_name = icon_name;
                    this.icon_button.set_icon_name(icon_name);
                    icon_popover.popdown();
                });
                icon_flow_box.insert(button, -1);
            }

            icon_card.set_child(icon_card_box);
            main_box.append(icon_card);

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

        private void draw_color_swatch(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            var rgba = Gdk.RGBA();
            rgba.parse(this.selected_color);
            cr.set_source_rgba(rgba.red, rgba.green, rgba.blue, rgba.alpha);
            cr.arc(width/2.0, height/2.0, width/2.0 - 8, 0, 2 * Math.PI);
            cr.fill();
        }

        public string? get_selected_icon_name() {
            return this.selected_icon_name;
        }

        public string get_selected_color() {
            return this.selected_color;
        }

        public void set_selected_color(string color) {
            this.selected_color = color;
            var da = this.color_swatch_button.get_child() as Gtk.DrawingArea;
            if (da != null) {
                da.queue_draw();
            }
        }

        public void set_selected_icon_name(string? icon_name) {
            this.selected_icon_name = icon_name;
            if (icon_name != null) {
                this.icon_button.set_icon_name(icon_name);
            }
        }

        public void prefill(string name, string color, string? icon_name) {
            this.name_entry.get_internal_entry ().text = name;
            this.set_selected_color (color);
            this.set_selected_icon_name (icon_name);
        }
    }
}
