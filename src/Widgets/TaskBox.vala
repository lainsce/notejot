namespace Notejot {
    public class Widgets.TaskBox : Gtk.Grid {
        private MainWindow win;
        public string color = "#FFE16B";
        public string title = "New Note…";
        public string contents = "Write a new note…";
        private int uid;
        private static int uid_counter;
        public Gtk.Grid main_grid;
        public Gtk.Box bar;
        public Gtk.Label task_label;
        public bool is_grid  {get; set; default = false;}

        public TaskBox (MainWindow win, string title, string contents, string color, bool is_grid) {
            this.win = win;
            this.color = color;
            this.title = title;
            this.contents = contents;
            this.get_style_context ().add_class ("notejot-column-box");

            this.uid = uid_counter++;
            update_theme ();

            win.tm.save_notes ();

            // Used to make up the colored badge
            var dummy_badge = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            dummy_badge.margin = 6;
            dummy_badge.valign = Gtk.Align.CENTER;
            dummy_badge.margin_top = dummy_badge.margin_bottom = 0;
            dummy_badge.get_style_context ().add_class ("notejot-dbg-%d".printf(uid));

            var dummy_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            dummy_box.margin = 6;
            dummy_box.valign = Gtk.Align.CENTER;
            dummy_box.margin_top = dummy_box.margin_bottom = 0;
            dummy_box.get_style_context ().add_class ("notejot-dbx-%d".printf(uid));

            bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            bar.margin = 6;
            bar.margin_top = bar.margin_bottom = 0;
            var bar_c = bar.get_style_context ();
            bar_c.add_class ("notejot-bar");

            task_label = new Gtk.Label (this.title);
            task_label.halign = Gtk.Align.START;
            task_label.wrap = true;
            task_label.hexpand = true;
            task_label.max_width_chars = 20;
            task_label.ellipsize = Pango.EllipsizeMode.END;

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

            var delete_note_button = new Gtk.ModelButton ();
			delete_note_button.text = (_("Delete Note"));

			delete_note_button.clicked.connect (() => {
                this.get_parent ().destroy ();
                win.tm.save_notes ();
                if (win.column.get_children () == null) {
                    win.views_box.sensitive = false;
                    if (win.stack.get_visible_child () == win.list_view || win.stack.get_visible_child () == win.grid_view) {
                        win.stack.set_visible_child (win.normal_view);
                    }
                }
			});

            var setting_grid = new Gtk.Grid ();
            setting_grid.margin = 6;
            setting_grid.column_spacing = 6;
            setting_grid.row_spacing = 6;
            setting_grid.orientation = Gtk.Orientation.VERTICAL;
            setting_grid.attach (color_button_label, 0, 0, 1, 1);
            setting_grid.attach (color_button_box, 0, 1, 1, 1);
            setting_grid.attach (delete_note_button, 0, 2, 1, 1);
            setting_grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (setting_grid);

            var app_button = new Gtk.MenuButton();
            app_button.has_tooltip = true;
            app_button.tooltip_text = (_("Settings"));
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            app_button.popover = popover;

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

            bar.pack_end (app_button);

            if (is_grid == false) {
                this.orientation = Gtk.Orientation.HORIZONTAL;
                this.add (dummy_badge);
                this.add (task_label);
                this.add (bar);
                app_button.valign = Gtk.Align.CENTER;
                app_button.vexpand = true;
            } else {
                this.set_size_request (200,200);
                this.get_style_context ().add_class ("notejot-note-grid");
                this.get_style_context ().add_class ("notejot-note-grid-%d".printf(uid));
                this.orientation = Gtk.Orientation.VERTICAL;
                this.halign = Gtk.Align.CENTER;
                this.valign = Gtk.Align.CENTER;
                this.row_spacing = 12;
                this.add (dummy_box);
                this.add (task_label);
                this.add (bar);
                app_button.valign = Gtk.Align.END;
                app_button.vexpand = true;
                task_label.margin_start = 6;
                task_label.margin_top = 6;
            }
            
            this.expand = false;
            
            this.show_all ();
        }

        private void update_theme() {
            var css_provider = new Gtk.CssProvider();

            string style = null;
            style = (N_("""
            .notejot-dbx-%d {
                padding: 10px;
                border-radius: 8px 8px 0 0;
            }
            .notejot-dbg-%d {
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
            .notejot-note-grid-%d {
                background: linear-gradient(to bottom, %s, %s, @base_color, @base_color, @base_color, @base_color, @base_color, @base_color, @base_color, @base_color)
            }
            """)).printf(uid, uid, color, uid, color, color);

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
