namespace Notejot {
    public class TagRow : Gtk.ListBoxRow {
        public signal void edit_requested (string uuid);
        public signal void deleted (string uuid);

        public string? tag_uuid { get; private set; }
        public string display_name { get; private set; }
        public string tag_color { get; private set; }

        public TagRow (string? color, string name, string count, string? icon_name, string? uuid) {
            this.tag_uuid = uuid;
            this.display_name = name;
            this.tag_color = color;
            this.add_css_class ("tag-row");

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            box.set_margin_start (6);
            box.set_margin_end (6);
            box.set_margin_top (6);
            box.set_margin_bottom (6);

            var overlay = new Gtk.Overlay ();
            overlay.set_size_request (32, 32);
            box.append (overlay);

            // Add CSS for selected state with tag color
            /*
             * Remove all possible tag-row-* classes first
             */
            this.remove_css_class ("tag-row-default");
            this.remove_css_class ("tag-row-red");
            this.remove_css_class ("tag-row-orange");
            this.remove_css_class ("tag-row-yellow");
            this.remove_css_class ("tag-row-green");
            this.remove_css_class ("tag-row-mint");
            this.remove_css_class ("tag-row-teal");
            this.remove_css_class ("tag-row-cyan");
            this.remove_css_class ("tag-row-blue");
            this.remove_css_class ("tag-row-indigo");
            this.remove_css_class ("tag-row-purple");
            this.remove_css_class ("tag-row-pink");
            this.remove_css_class ("tag-row-brown");

            var color_class = get_color_class (color);
            if (color_class != null) {
                this.add_css_class ("tag-row-" + color_class);
            }

            if (color != null) {
                var color_swatch = new Gtk.DrawingArea ();
                color_swatch.set_content_width (32);
                color_swatch.set_content_height (32);
                color_swatch.set_draw_func ((area, cr, width, height) => {
                    var rgba = Gdk.RGBA ();
                    rgba.parse (color);
                    cr.set_source_rgba (rgba.red, rgba.green, rgba.blue, rgba.alpha);
                    cr.arc (width / 2.0, height / 2.0, width / 2.0, 0, 2 * Math.PI);
                    cr.fill ();
                });
                overlay.set_child (color_swatch);
            } else {
                var color_swatch = new Gtk.DrawingArea ();
                color_swatch.set_content_width (32);
                color_swatch.set_content_height (32);
                color_swatch.set_draw_func ((area, cr, width, height) => {
                    var rgba = Gdk.RGBA ();
                    rgba.parse ("#e3e2e8");
                    cr.set_source_rgba (rgba.red, rgba.green, rgba.blue, rgba.alpha);
                    cr.arc (width / 2.0, height / 2.0, width / 2.0, 0, 2 * Math.PI);
                    cr.fill ();
                });
                overlay.set_child (color_swatch);
            }

            if (icon_name != null && color != null) {
                var icon = new Gtk.Image.from_icon_name (icon_name);
                icon.add_css_class ("inverted-icon");
                icon.set_pixel_size (16);
                icon.set_halign (Gtk.Align.CENTER);
                icon.set_valign (Gtk.Align.CENTER);
                overlay.add_overlay (icon);
            } else if (icon_name != null) {
                var icon = new Gtk.Image.from_icon_name (icon_name);
                icon.set_pixel_size (16);
                icon.set_halign (Gtk.Align.CENTER);
                icon.set_valign (Gtk.Align.CENTER);
                overlay.add_overlay (icon);
            }

            var label = new Gtk.Label (name);
            label.add_css_class ("tag-label");
            label.set_hexpand (true);
            label.set_valign (Gtk.Align.CENTER);
            label.margin_top = 3;
            label.set_xalign (0.0f);

            var count_label = new Gtk.Label (count);
            count_label.set_valign (Gtk.Align.CENTER);
            count_label.margin_top = 3;
            count_label.margin_end = 9;
            count_label.add_css_class ("tag-count-label");

            box.append (label);

            // Only show actions for user-created tags
            if (this.tag_uuid != null && this.tag_uuid != "deleted") {
                var edit_button = new He.Button ("document-edit-symbolic", "");
                edit_button.add_css_class ("tag-edit-button");
                edit_button.set_halign (Gtk.Align.END);
                edit_button.set_valign (Gtk.Align.CENTER);
                edit_button.set_tooltip_text (_("Edit Tag"));
                edit_button.clicked.connect (() => {
                    if (this.tag_uuid != null) {
                        edit_requested (this.tag_uuid);
                    }
                });

                var delete_button = new He.Button ("user-trash-symbolic", "");
                delete_button.add_css_class ("tag-delete-button");
                delete_button.set_halign (Gtk.Align.END);
                delete_button.set_valign (Gtk.Align.CENTER);
                delete_button.set_tooltip_text (_("Delete Tag"));
                delete_button.clicked.connect (() => {
                    if (this.tag_uuid != null) {
                        deleted (this.tag_uuid);
                    }
                });

                box.append (edit_button);
                box.append (delete_button);
            }

            box.append (count_label);
            this.set_child (box);
        }

        private string get_color_class (string? color) {
            if (color == null)
                return "default";
            switch (color.down ()) {
            case "#e57373": case "#ef5350": return "red";
            case "#ffb74d": case "#ffa726": return "orange";
            case "#ffd54f": case "#ffe082": return "yellow";
            case "#81c784": case "#66bb6a": return "green";
            case "#4db6ac": case "#26a69a": return "mint";
            case "#4dd0e1": case "#26c6da": return "teal";
            case "#32ade6": case "#29b6f6": return "cyan";
            case "#64b5f6": case "#42a5f5": return "blue";
            case "#7986cb": case "#5c6bc0": return "indigo";
            case "#ba68c8": case "#ab47bc": return "purple";
            case "#f06292": case "#ec407a": return "pink";
            case "#bcaaa4": case "#a1887f": return "brown";
            default: return "default";
            }
        }
    }
}
