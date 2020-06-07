namespace Notejot {
    public class Widgets.TaskBox : Gtk.Grid {
        private MainWindow win;
        public string contents = "";
        public string color = "#fff394";
        private int uid;
        private static int uid_counter;

        public TaskBox (MainWindow win, string contents, string color) {
            this.win = win;
            this.color = color;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.contents = contents;

            this.uid = uid_counter++;
            update_theme ();

            win.tm.save_notes ();

            var view = new Gtk.TextView ();
            view.hexpand = true;
            view.set_size_request (-1, 250);
            view.margin = 3;
            view.margin_top = view.margin_bottom = 0;
            view.top_margin = view.bottom_margin = view.left_margin = view.right_margin = 12;
            view.get_style_context ().add_class ("notejot-view-%d".printf(uid));
            view.buffer.text = this.contents;

            view.buffer.changed.connect (() => {
                this.contents = view.buffer.text;
                win.tm.save_notes ();
            });

            // Used to make up the top part of the notes
            var dummy_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            dummy_box.margin = 3;
            dummy_box.margin_top = dummy_box.margin_bottom = 0;
            dummy_box.get_style_context ().add_class ("notejot-db-%d".printf(uid));

            var task_delete_button = new Gtk.Button();
            var task_delete_button_c = task_delete_button.get_style_context ();
            task_delete_button_c.add_class ("flat");
            task_delete_button.has_tooltip = true;
            task_delete_button.vexpand = false;
            task_delete_button.valign = Gtk.Align.CENTER;
            task_delete_button.set_image (new Gtk.Image.from_icon_name (
                                             "edit-delete-symbolic",
                                             Gtk.IconSize.SMALL_TOOLBAR
                                          ));
            task_delete_button.tooltip_text = (_("Delete Note"));

            var bar = new Gtk.ActionBar ();
            bar.margin = 3;
            bar.margin_top = bar.margin_bottom = 0;
            var bar_c = bar.get_style_context ();
            bar_c.add_class ("notejot-bar-%d".printf(uid));
            bar.pack_start (task_delete_button);

            var color_button_red = new Gtk.Button ();
            color_button_red.has_focus = false;
            color_button_red.halign = Gtk.Align.CENTER;
            color_button_red.height_request = 24;
            color_button_red.width_request = 24;
            color_button_red.tooltip_text = _("Red");

            var color_button_red_context = color_button_red.get_style_context ();
            color_button_red_context.add_class ("color-button");
            color_button_red_context.add_class ("color-red");

            var color_button_orange = new Gtk.Button ();
            color_button_orange.has_focus = false;
            color_button_orange.halign = Gtk.Align.CENTER;
            color_button_orange.height_request = 24;
            color_button_orange.width_request = 24;
            color_button_orange.tooltip_text = _("Orange");

            var color_button_orange_context = color_button_orange.get_style_context ();
            color_button_orange_context.add_class ("color-button");
            color_button_orange_context.add_class ("color-orange");

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
            color_button_box.pack_start (color_button_orange, false, true, 0);
            color_button_box.pack_start (color_button_yellow, false, true, 0);
            color_button_box.pack_start (color_button_green, false, true, 0);
            color_button_box.pack_start (color_button_blue, false, true, 0);
            color_button_box.pack_start (color_button_indigo, false, true, 0);

            var color_button_label = new Granite.HeaderLabel (_("Note Color"));

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
                this.color = "#ff8c82";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_orange.clicked.connect (() => {
                this.color = "#ffc27d";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_yellow.clicked.connect (() => {
                this.color = "#fff394";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_green.clicked.connect (() => {
                this.color = "#d1ff82";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_blue.clicked.connect (() => {
                this.color = "#8cd5ff";
                update_theme();
                win.tm.save_notes ();
            });

            color_button_indigo.clicked.connect (() => {
                this.color = "#aca9fd";
                update_theme();
                win.tm.save_notes ();
            });

            bar.pack_end (app_button);

            task_delete_button.clicked.connect (() => {
                this.destroy ();
                win.tm.save_notes ();
            });

            this.add (dummy_box);
            this.add (view);
            this.add (bar);
            this.show_all ();
        }

        private void update_theme() {
            var css_provider = new Gtk.CssProvider();

            string style = null;
            if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                style = (N_("""
                .notejot-bar-%d {
                    background-color: #F7F7F7;
                    box-shadow: none;
                    background-image: none;
                    padding: 3px;
                }
                .notejot-bar-%d image {
                    color: #323232;
                    padding: 3px;
                    box-shadow: none;
                    background-image: none;
                }
                .notejot-view-%d,
                .notejot-view-%d text {
                    background-color: #F7F7F7;
                    background-image: none;
                    font-size: 1.2em;
                    color: #323232;
                }
                .notejot-bar-%d {
                    border-radius: 0 0 10px 10px;
                    box-shadow:
                        0 0 0 1px rgba (0, 0, 0, 0.1),
                        0 3px 4px rgba (0, 0, 0, 0.15),
                        0 3px 3px -3px rgba (0, 0, 0, 0.35);
                }
                .notejot-db-%d {
                    border-radius: 10px 10px 0 0;
                    border-bottom: 2px dashed alpha(black, 0.35);
                    background: %s;
                    padding: 10px;
                    box-shadow:
                        inset 1px 0 0 0 rgba (255, 255, 255, 0.07),
                        inset -1px 0 0 0 rgba (255, 255, 255, 0.07);
                }
                """)).printf(uid, uid, uid, uid, uid, uid, color);
            } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                style = (N_("""
                .notejot-bar-%d {
                    background-color: #323232;
                    box-shadow: none;
                    background-image: none;
                    padding: 3px;
                }
                .notejot-bar-%d image {
                    color: #F7F7F7;
                    padding: 3px;
                    box-shadow: none;
                    background-image: none;
                }
                .notejot-view-%d,
                .notejot-view-%d text {
                    background-color: #323232;
                    background-image: none;
                    font-size: 1.2em;
                    color: #F7F7F7;
                }
                .notejot-bar-%d {
                    border-radius: 0 0 10px 10px;
                    box-shadow:
                        0 0 0 1px rgba (0, 0, 0, 0.1),
                        0 3px 4px rgba (0, 0, 0, 0.15),
                        0 3px 3px -3px rgba (0, 0, 0, 0.35);
                }
                .notejot-db-%d {
                    border-radius: 10px 10px 0 0;
                    border-bottom: 2px dashed alpha(black, 0.35);
                    background: shade(%s, 0.8);
                    padding: 10px;
                    box-shadow:
                        inset 1px 0 0 0 rgba (255, 255, 255, 0.07),
                        inset -1px 0 0 0 rgba (255, 255, 255, 0.07);
                }
                """)).printf(uid, uid, uid, uid, uid, uid, color);
            } else {
                style = (N_("""
                .notejot-bar-%d {
                    background-color: #323232;
                    box-shadow: none;
                    background-image: none;
                    padding: 3px;
                }
                .notejot-bar-%d image {
                    color: #F7F7F7;
                    padding: 3px;
                    box-shadow: none;
                    background-image: none;
                }
                .notejot-view-%d,
                .notejot-view-%d text {
                    background-color: #323232;
                    background-image: none;
                    font-size: 1.2em;
                    color: #F7F7F7;
                }
                .notejot-bar-%d {
                    border-radius: 0 0 10px 10px;
                    box-shadow:
                        0 0 0 1px rgba (0, 0, 0, 0.1),
                        0 3px 4px rgba (0, 0, 0, 0.15),
                        0 3px 3px -3px rgba (0, 0, 0, 0.35);
                }
                .notejot-db-%d {
                    border-radius: 10px 10px 0 0;
                    border-bottom: 2px dashed alpha(black, 0.35);
                    background: shade(%s, 0.8);
                    padding: 10px;
                    box-shadow:
                        inset 1px 0 0 0 rgba (255, 255, 255, 0.07),
                        inset -1px 0 0 0 rgba (255, 255, 255, 0.07);
                }
                """)).printf(uid, uid, uid, uid, uid, uid, color);
            }

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
