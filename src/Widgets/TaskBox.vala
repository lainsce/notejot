namespace Notejot {
    public class Widgets.TaskBox : Gtk.ListBoxRow {
        private MainWindow win;
        public string color = "#FFE16B";
        public string title = "";
        public string contents = "";
        private int uid;
        private static int uid_counter;
        public Gtk.Grid main_grid;
        public Gtk.Box bar;
        public Gtk.Label task_label;

        public TaskBox (MainWindow win, string title, string contents, string color) {
            this.win = win;
            this.color = color;
            this.title = title;
            this.contents = contents;
            this.get_style_context ().add_class ("notejot-column-box");

            this.uid = uid_counter++;
            update_theme ();

            win.tm.save_notes ();

            // Used to make up the colored badge
            var dummy_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            dummy_box.margin = 6;
            dummy_box.valign = Gtk.Align.CENTER;
            dummy_box.margin_top = dummy_box.margin_bottom = 0;
            dummy_box.get_style_context ().add_class ("notejot-db-%d".printf(uid));

            bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            bar.margin = 6;
            bar.margin_top = bar.margin_bottom = 0;
            var bar_c = bar.get_style_context ();
            bar_c.add_class ("notejot-bar");

            task_label = new Gtk.Label (title);
            task_label.halign = Gtk.Align.START;
            task_label.wrap = true;
            task_label.hexpand = true;
            task_label.max_width_chars = 20;
            task_label.ellipsize = Pango.EllipsizeMode.END;

            var color_button_red = new Gtk.Button ();
            color_button_red.has_focus = false;
            color_button_red.halign = Gtk.Align.CENTER;
            color_button_red.height_request = 24;
            color_button_red.width_request = 24;
            color_button_red.tooltip_text = _("Red");

            var color_button_red_context = color_button_red.get_style_context ();
            color_button_red_context.add_class ("color-button");
            color_button_red_context.add_class ("color-red");

            var color_button_yellow = new Gtk.Button ();
            color_button_yellow.has_focus = false;
            color_button_yellow.halign = Gtk.Align.CENTER;
            color_button_yellow.height_request = 24;
            color_button_yellow.width_request = 24;
            color_button_yellow.tooltip_text = _("Yellow");

            var color_button_yellow_context = color_button_yellow.get_style_context ();
            color_button_yellow_context.add_class ("color-button");
            color_button_yellow_context.add_class ("color-yellow");

            var color_button_green = new Gtk.Button ();
            color_button_green.has_focus = false;
            color_button_green.halign = Gtk.Align.CENTER;
            color_button_green.height_request = 24;
            color_button_green.width_request = 24;
            color_button_green.tooltip_text = _("Green");

            var color_button_green_context = color_button_green.get_style_context ();
            color_button_green_context.add_class ("color-button");
            color_button_green_context.add_class ("color-green");

            var color_button_blue = new Gtk.Button ();
            color_button_blue.has_focus = false;
            color_button_blue.halign = Gtk.Align.CENTER;
            color_button_blue.height_request = 24;
            color_button_blue.width_request = 24;
            color_button_blue.tooltip_text = _("Blue");

            var color_button_blue_context = color_button_blue.get_style_context ();
            color_button_blue_context.add_class ("color-button");
            color_button_blue_context.add_class ("color-blue");

            var color_button_indigo = new Gtk.Button ();
            color_button_indigo.has_focus = false;
            color_button_indigo.halign = Gtk.Align.CENTER;
            color_button_indigo.height_request = 24;
            color_button_indigo.width_request = 24;
            color_button_indigo.tooltip_text = _("Indigo");

            var color_button_indigo_context = color_button_indigo.get_style_context ();
            color_button_indigo_context.add_class ("color-button");
            color_button_indigo_context.add_class ("color-indigo");

            var color_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            color_button_box.pack_start (color_button_red, false, true, 0);
            color_button_box.pack_start (color_button_yellow, false, true, 0);
            color_button_box.pack_start (color_button_green, false, true, 0);
            color_button_box.pack_start (color_button_blue, false, true, 0);
            color_button_box.pack_start (color_button_indigo, false, true, 0);

            var color_button_label = new Granite.HeaderLabel (_("Note Badge Color"));

            var setting_grid = new Gtk.Grid ();
            setting_grid.margin = 6;
            setting_grid.column_spacing = 6;
            setting_grid.row_spacing = 6;
            setting_grid.orientation = Gtk.Orientation.VERTICAL;
            setting_grid.attach (color_button_label, 0, 0, 1, 1);
            setting_grid.attach (color_button_box, 0, 1, 1, 1);
            setting_grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (setting_grid);

            var app_button = new Gtk.MenuButton();
            app_button.has_tooltip = true;
            app_button.tooltip_text = (_("Settings"));
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            app_button.popover = popover;

            color_button_red.clicked.connect (() => {
                this.color = "#ED5353";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_yellow.clicked.connect (() => {
                this.color = "#FFE16B";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_green.clicked.connect (() => {
                this.color = "#9BDB4D";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_blue.clicked.connect (() => {
                this.color = "#64BAFF";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_indigo.clicked.connect (() => {
                this.color = "#CD9EF7";
                update_theme();
                win.tm.save_notes ();
            });

            bar.pack_end (app_button);

            main_grid = new Gtk.Grid ();
            main_grid.orientation = Gtk.Orientation.HORIZONTAL;
            main_grid.margin_bottom = 6;
            main_grid.margin_top = 6;
            main_grid.expand = false;
            main_grid.add (dummy_box);
            main_grid.add (task_label);
            main_grid.add (bar);

            this.add(main_grid);
            this.show_all ();
        }

        private void update_theme() {
            var css_provider = new Gtk.CssProvider();

            string style = null;
            style = (N_("""
            .notejot-db-%d {
                border: 1px solid alpha(black, 0.25);
                background: %s;
                border-radius: 8px;
                padding: 5px;
                box-shadow:
                    0 1px 0 0 alpha(@highlight_color, 0.3),
                    inset 0 1px 1px alpha(black, 0.05),
                    inset 0 0 1px 1px alpha(black, 0.05),
                    0 1px 0 0 alpha(@highlight_color, 0.2);
            }
            """)).printf(uid, color);

            try {
                css_provider.load_from_data(style, -1);
            } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
            }

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
    }
}
