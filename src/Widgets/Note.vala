namespace Notejot {
    public class Widgets.Note : Gtk.Grid {
        private MainWindow win;
        private int uid;
        private static int uid_counter;
        public Gtk.Box bar;
        public Gtk.Box dummy_box;
        public Gtk.Label task_label;
        public Gtk.ModelButton delete_note_button;
        public string color = "#FFE16B";
        public string contents = "Write a new note…";
        public string title = "New Note…";

        public Note (MainWindow win, string title, string contents, string color) {
            this.color = color;
            this.contents = contents;
            this.title = title;
            this.win = win;
            this.uid = uid_counter++;
            this.margin_start = this.margin_end = 6;
            this.get_style_context ().add_class ("notejot-column-box");

            update_theme ();
            win.tm.save_notes ();

            // Used to make up the colored badge
            dummy_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin = 6,
                margin_top = 0,
                margin_bottom = 0,
                valign = Gtk.Align.CENTER
            };
            dummy_box.get_style_context ().add_class ("notejot-db-%d".printf(uid));

            bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                margin = 6,
                margin_top = 0,
                margin_bottom = 0
            };
            bar.get_style_context ().add_class ("notejot-bar");

            task_label = new Gtk.Label (this.title) {
                halign = Gtk.Align.START,
                wrap = true,
                hexpand = true,
                ellipsize = Pango.EllipsizeMode.END
            };

            var color_button_red = new Gtk.RadioButton (null) {
                tooltip_text = _("Red")
            };
            color_button_red.get_style_context ().add_class ("color-button");
            color_button_red.get_style_context ().add_class ("color-red");

            var color_button_orange = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Orange")
            };
            color_button_orange.get_style_context ().add_class ("color-button");
            color_button_orange.get_style_context ().add_class ("color-orange");

            var color_button_yellow = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Yellow")
            };
            color_button_yellow.get_style_context ().add_class ("color-button");
            color_button_yellow.get_style_context ().add_class ("color-yellow");

            var color_button_green = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Green")
            };
            color_button_green.get_style_context ().add_class ("color-button");
            color_button_green.get_style_context ().add_class ("color-green");

            var color_button_blue = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Blue")
            };
            color_button_blue.get_style_context ().add_class ("color-button");
            color_button_blue.get_style_context ().add_class ("color-blue");

            var color_button_indigo = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Indigo")
            };
            color_button_indigo.get_style_context ().add_class ("color-button");
            color_button_indigo.get_style_context ().add_class ("color-indigo");

            var color_button_neutral = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Gray")
            };
            color_button_neutral.get_style_context ().add_class ("color-button");
            color_button_neutral.get_style_context ().add_class ("color-neutral");

            var color_button_box = new Gtk.Grid () {
                margin_start = 12,
                column_spacing = 6
            };
            color_button_box.add (color_button_red);
            color_button_box.add (color_button_orange);
            color_button_box.add (color_button_yellow);
            color_button_box.add (color_button_green);
            color_button_box.add (color_button_blue);
            color_button_box.add (color_button_indigo);
            color_button_box.add (color_button_neutral);

            var color_button_label = new Granite.HeaderLabel (_("Note Badge Color"));

            delete_note_button = new Gtk.ModelButton ();
			delete_note_button.text = (_("Delete Note"));

            var setting_grid = new Gtk.Grid () {
                margin = 6,
                column_spacing = 6,
                row_spacing = 6,
                orientation = Gtk.Orientation.VERTICAL
            };
            setting_grid.attach (color_button_label, 0, 0, 1, 1);
            setting_grid.attach (color_button_box, 0, 1, 1, 1);
            setting_grid.attach (delete_note_button, 0, 2, 1, 1);
            setting_grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (setting_grid);

            var app_button = new Gtk.MenuButton() {
                tooltip_text = (_("Settings")),
                image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                popover = popover
            };
            bar.pack_end (app_button);

            color_button_red.clicked.connect (() => {
                this.color = "#D07070";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_orange.clicked.connect (() => {
                this.color = "#FF976B";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_yellow.clicked.connect (() => {
                this.color = "#FFE16B";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_green.clicked.connect (() => {
                this.color = "#74C02E";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_blue.clicked.connect (() => {
                this.color = "#70C0FF";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_indigo.clicked.connect (() => {
                this.color = "#6060C5";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_neutral.clicked.connect (() => {
                this.color = "#888888";
                update_theme();
                win.tm.save_notes ();
            });

            delete_note_button.clicked.connect (() => {
			    this.get_parent ().destroy ();
                win.tm.save_notes ();
            });

            if (win.noteview != null) {
                win.noteview.editablelabel.changed.connect (() => {
                    task_label.set_label(win.noteview.editablelabel.title.get_label ());
                    title = win.noteview.editablelabel.title.get_label ();
                    win.tm.save_notes ();
                });
            }

            this.margin_bottom = 6;
            this.margin_top = 6;
            this.expand = false;
            this.add (dummy_box);
            this.add (task_label);
            this.add (bar);
            this.show_all ();
        }

        private void update_theme() {
            var css_provider = new Gtk.CssProvider();
            string style = null;
            style = ("""
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
            """).printf(uid, color);
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