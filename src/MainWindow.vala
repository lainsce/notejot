/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Notejot {
    public class MainWindow : Gtk.Window {
        private Gtk.ModelButton delete_item;
        private Gtk.SourceView view = new Gtk.SourceView ();
        private Gtk.HeaderBar header;
        private int uid;
        private static int uid_counter = 0;
        public string color = "#fff394";
        public string content = "";
        public string title_name = "Notejot";
        public Notejot.EditableLabel label;

        public SimpleActionGroup actions { get; construct; }

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_NEW = "action_new";
        public const string ACTION_DELETE = "action_delete";

        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_NEW, action_new },
            { ACTION_DELETE, action_delete }
        };

        public MainWindow (Gtk.Application app, Storage? storage) {
            Object (application: app,
                    resizable: false,
                    height_request: 300,
                    width_request: 300);

            var actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            if (storage != null) {
                init_from_storage(storage);
            } else {
                this.color = "#fff394";
                this.content = "";
                this.set_position(Gtk.WindowPosition.CENTER);
                this.title_name = "Notejot";
                set_title (this.title_name);
            }

            this.get_style_context().add_class("rounded");
            this.uid = uid_counter++;

            update_theme();

            header = new Gtk.HeaderBar();
            header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            header.has_subtitle = false;
            create_app_menu ();
            header.set_show_close_button (true);

            label = new Notejot.EditableLabel (this.title_name);
            header.set_custom_title(label);
            this.set_titlebar(header);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            this.add (scrolled);

            view.bottom_margin = 10;
            view.buffer.text = this.content;
            view.expand = false;
            view.left_margin = 10;
            view.margin = 2;
            view.right_margin = 10;
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            view.top_margin = 10;
            scrolled.add (view);
            this.show_all();

            focus_out_event.connect (() => {
                update_storage ();
                return false;
            });

            label.changed.connect (() => {
                update_storage ();
            });

            view.buffer.changed.connect (() => {
                update_storage ();
            });
        }

        public new void set_title (string title) {
            this.title = title;
        }

        private void update_storage () {
            get_storage_note();
            ((Application)this.application).update_storage();
        }

        private void update_theme() {
            var css_provider = new Gtk.CssProvider();
            this.get_style_context().add_class("mainwindow-%d".printf(uid));
            this.get_style_context().add_class("window-%d".printf(uid));

            string style = null;
            string selected_color = this.color;
            if (Gtk.get_minor_version() < 20) {
                style = (N_("""
                @define-color textColorPrimary #1a1a1a;

                .mainwindow-%d {
                    background-color: %s;
                    box-shadow: #1a1a1a;
                }

                GtkTextView.view {
                    color: @textColorPrimary;
                    font-size: 11px;
                }

                GtkTextView.view:selected {
                    color: #FFFFFF;
                    background-color: #64baff;
                    font-size: 11px
                }

                GtkEntry.flat {
                    background: transparent;
                }

                .window-%d GtkTextView,
                .window-%d GtkHeaderBar {
                    background-color: %s;
                    border-bottom-color: %s;
                    box-shadow: none;
                }

                .color-button {
                    border-radius: 50%;
                    box-shadow:
                        inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                        inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                        0 1px 0 0 alpha (@bg_highlight_color, 0.3);
                }

                .color-button:focus {
                    border-color: @colorAccent;
                }

                .color-slate {
                    background-color: #a5b3bc;
                }

                .color-white {
                    background-color: #fafafa;
                }

                .color-red {
                    background-color: #ff9c92;
                }

                .color-orange {
                    background-color: #ffc27d;
                }

                .color-yellow {
                    background-color: #fff394;
                }

                .color-green {
                    background-color: #d1ff82;
                }

                .color-blue {
                    background-color: #8cd5ff;
                }

                .color-indigo {
                    background-color: #aca9fd;
                }

                .color-violet {
                    background-color: #e29ffc;
                }
                """)).printf(uid, selected_color, uid, uid, selected_color, selected_color);
            } else {
                style = (N_("""
                @define-color textColorPrimary #1a1a1a;

                .mainwindow-%d {
                    background-color: %s;
                    box-shadow: #1a1a1a;
                }

                textview.view:selected {
                    color: @textColorPrimary;
                    font-size: 14px;
                }

                textview.view:selected {
                    color: #FFFFFF;
                    background-color: #64baff;
                    font-size: 14px
                }

                entry.flat {
                    background: transparent;
                }

                .window-%d textview.view text,
                .window-%d headerbar {
                    background-color: %s;
                    border-bottom-color: %s;
                    box-shadow: none;
                }

                .color-button {
                    border-radius: 50%;
                    box-shadow:
                        inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                        inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                        0 1px 0 0 alpha (@bg_highlight_color, 0.3);
                }

                .color-button:focus {
                    border-color: @colorAccent;
                }

                .color-slate {
                    background-color: #a5b3bc;
                }

                .color-white {
                    background-color: #fafafa;
                }

                .color-red {
                    background-color: #ff9c92;
                }

                .color-orange {
                    background-color: #ffc27d;
                }

                .color-yellow {
                    background-color: #fff394;
                }

                .color-green {
                    background-color: #d1ff82;
                }

                .color-blue {
                    background-color: #8cd5ff;
                }

                .color-indigo {
                    background-color: #aca9fd;
                }

                .color-violet {
                    background-color: #e29ffc;
                }
                """)).printf(uid, selected_color, uid, uid, selected_color, selected_color);
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

        private void create_app_menu() {
            var new_item = new Gtk.ModelButton ();
            new_item.text = (_("New note"));
            new_item.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW;

            delete_item = new Gtk.ModelButton ();
            delete_item.text = (_("Delete note"));
            delete_item.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_DELETE;

            var color_button_white = new Gtk.Button ();
            color_button_white.halign = Gtk.Align.CENTER;
            color_button_white.height_request = 22;
            color_button_white.width_request = 22;
            color_button_white.tooltip_text = _("White");

            var color_button_white_context = color_button_white.get_style_context ();
            color_button_white_context.add_class ("color-button");
            color_button_white_context.add_class ("color-white");

            var color_button_red = new Gtk.Button ();
            color_button_red.halign = Gtk.Align.CENTER;
            color_button_red.height_request = 22;
            color_button_red.width_request = 22;
            color_button_red.tooltip_text = _("Red");

            var color_button_red_context = color_button_red.get_style_context ();
            color_button_red_context.add_class ("color-button");
            color_button_red_context.add_class ("color-red");

            var color_button_orange = new Gtk.Button ();
            color_button_orange.halign = Gtk.Align.CENTER;
            color_button_orange.height_request = 22;
            color_button_orange.width_request = 22;
            color_button_orange.tooltip_text = _("Orange");

            var color_button_orange_context = color_button_orange.get_style_context ();
            color_button_orange_context.add_class ("color-button");
            color_button_orange_context.add_class ("color-orange");

            var color_button_yellow = new Gtk.Button ();
            color_button_yellow.halign = Gtk.Align.CENTER;
            color_button_yellow.height_request = 22;
            color_button_yellow.width_request = 22;
            color_button_yellow.tooltip_text = _("Yellow");

            var color_button_yellow_context = color_button_yellow.get_style_context ();
            color_button_yellow_context.add_class ("color-button");
            color_button_yellow_context.add_class ("color-yellow");

            var color_button_green = new Gtk.Button ();
            color_button_green.halign = Gtk.Align.CENTER;
            color_button_green.height_request = 22;
            color_button_green.width_request = 22;
            color_button_green.tooltip_text = _("Green");

            var color_button_green_context = color_button_green.get_style_context ();
            color_button_green_context.add_class ("color-button");
            color_button_green_context.add_class ("color-green");

            var color_button_blue = new Gtk.Button ();
            color_button_blue.halign = Gtk.Align.CENTER;
            color_button_blue.height_request = 22;
            color_button_blue.width_request = 22;
            color_button_blue.tooltip_text = _("Blue");

            var color_button_blue_context = color_button_blue.get_style_context ();
            color_button_blue_context.add_class ("color-button");
            color_button_blue_context.add_class ("color-blue");

            var color_button_indigo = new Gtk.Button ();
            color_button_indigo.halign = Gtk.Align.CENTER;
            color_button_indigo.height_request = 22;
            color_button_indigo.width_request = 22;
            color_button_indigo.tooltip_text = _("Indigo");

            var color_button_indigo_context = color_button_indigo.get_style_context ();
            color_button_indigo_context.add_class ("color-button");
            color_button_indigo_context.add_class ("color-indigo");

            var color_button_violet = new Gtk.Button ();
            color_button_violet.halign = Gtk.Align.CENTER;
            color_button_violet.height_request = 22;
            color_button_violet.width_request = 22;
            color_button_violet.tooltip_text = _("Violet");

            var color_button_violet_context = color_button_violet.get_style_context ();
            color_button_violet_context.add_class ("color-button");
            color_button_violet_context.add_class ("color-violet");

            var color_button_slate = new Gtk.Button ();
            color_button_slate.halign = Gtk.Align.CENTER;
            color_button_slate.height_request = 22;
            color_button_slate.width_request = 22;
            color_button_slate.tooltip_text = _("Slate");

            var color_button_slate_context = color_button_slate.get_style_context ();
            color_button_slate_context.add_class ("color-button");
            color_button_slate_context.add_class ("color-slate");

            var color_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            color_button_box.margin_start = 6;
            color_button_box.pack_start (color_button_white, false, true, 0);
            color_button_box.pack_start (color_button_red, false, true, 0);
            color_button_box.pack_start (color_button_orange, false, true, 0);
            color_button_box.pack_start (color_button_yellow, false, true, 0);
            color_button_box.pack_start (color_button_green, false, true, 0);
            color_button_box.pack_start (color_button_blue, false, true, 0);
            color_button_box.pack_start (color_button_indigo, false, true, 0);
            color_button_box.pack_start (color_button_violet, false, true, 0);
            color_button_box.pack_start (color_button_slate, false, true, 0);

            var setting_grid = new Gtk.Grid ();
            setting_grid.margin = 6;
            setting_grid.column_spacing = 6;
            setting_grid.row_spacing = 12;
            setting_grid.orientation = Gtk.Orientation.VERTICAL;
            setting_grid.attach (new_item, 0, 0, 1, 1);
            setting_grid.attach (color_button_box, 0, 1, 1, 1);
            setting_grid.attach (delete_item, 0, 2, 1, 1);
            setting_grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (setting_grid);

            var app_button = new Gtk.MenuButton();
            app_button.has_tooltip = true;
            app_button.tooltip_text = (_("Settings"));
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            app_button.popover = popover;

            color_button_white.clicked.connect (() => {
                this.color = "#F5F5F5";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_red.clicked.connect (() => {
                this.color = "#ff9c92";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_orange.clicked.connect (() => {
                this.color = "#ffc27d";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_yellow.clicked.connect (() => {
                this.color = "#fff394";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_green.clicked.connect (() => {
                this.color = "#d1ff82";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_blue.clicked.connect (() => {
                this.color = "#8cd5ff";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_indigo.clicked.connect (() => {
                this.color = "#aca9fd";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_violet.clicked.connect (() => {
                this.color = "#e29ffc";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_slate.clicked.connect (() => {
                this.color = "#a5b3bc";
                update_theme();
                ((Application)this.application).update_storage();
            });

            header.pack_end(app_button);
        }

        private void init_from_storage(Storage storage) {
            this.color = storage.color;
            this.content = storage.content;
            this.move((int)storage.x, (int)storage.y);
            this.title_name = storage.title;
            set_title (this.title_name);
        }

        private void action_new () {
            ((Application)this.application).create_note(null);
        }

        private void action_delete () {
            ((Application)this.application).remove_note(this);
            this.destroy ();
        }

        public Storage get_storage_note() {
            int x, y;
            string color = this.color;
            Gtk.TextIter start,end;
            view.buffer.get_bounds (out start, out end);
            this.content = view.buffer.get_text (start, end, true);
            this.title_name = label.title.get_label ();
            set_title (this.title_name);

            this.get_position (out x, out y);

            return new Storage.from_storage(x, y, color, content, title_name);
        }

        public override bool delete_event (Gdk.EventAny event) {
            var settings = AppSettings.get_default ();

            int x, y;
            this.get_position (out x, out y);
            settings.window_x = x;
            settings.window_y = y;
            return false;
        }
    }
}
