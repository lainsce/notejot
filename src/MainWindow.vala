/*
* Copyright (c) 2417 Lains
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
        private Gtk.Button delete_item;
        private new Gtk.SourceBuffer buffer;
        private Gtk.SourceView view;
        private Gtk.HeaderBar header;
        private Gtk.ActionBar actionbar;
        private int uid;
        private static int uid_counter = 0;
        public string color = "#fff394";
        public string selected_color_text = "#ad5f00";
        public bool pinned = false;
        public string content = "";
        public string title_name = "Notejot";
        public Notejot.EditableLabel label;

        public SimpleActionGroup actions { get; construct; }

        public const string ACTION_PREFIX   = "win.";
        public const string ACTION_NEW      = "action_new";
        public const string ACTION_DELETE   = "action_delete";
        public const string ACTION_UNDO     = "action_undo";
        public const string ACTION_REDO     = "action_redo";

        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_NEW,       action_new      },
            { ACTION_DELETE,    action_delete   },
            { ACTION_UNDO,      action_new      },
            { ACTION_REDO,      action_delete   }
        };

        public MainWindow (Gtk.Application app, Storage? storage) {
            Object (application: app);

            var actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            if (storage != null) {
                init_from_storage(storage);
            } else {
                this.color = "#fff394";
                this.selected_color_text = "#ad5f00";
                this.pinned = false;
                this.content = "";
                this.set_position(Gtk.WindowPosition.CENTER);
                this.title_name = "Notejot";
                set_title (this.title_name);
            }

            this.get_style_context().add_class("rounded");
            this.get_style_context().add_class("default-decoration");
            this.get_style_context().add_class("notejot-window");
            this.uid = uid_counter++;

            update_theme();

            header = new Gtk.HeaderBar();
            header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            header.get_style_context().add_class("notejot-title");
            header.has_subtitle = false;
            header.set_show_close_button (true);
            header.decoration_layout = "close:";

            var applet_button = new Gtk.ToggleButton ();
            applet_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var applet_button_image = new Gtk.Image.from_icon_name ("view-pin-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            applet_button.set_image (applet_button_image);

            if (pinned) {
                applet_button.set_active (true);
                applet_button.get_style_context().add_class("rotated");
                set_keep_below (pinned);
                stick ();
            } else {
                applet_button.set_active (false);
                applet_button.get_style_context().remove_class("rotated");
            }

            applet_button.toggled.connect (() => {
                if (applet_button.active) {
                    pinned = true;
                    applet_button.get_style_context().add_class("rotated");
                    set_keep_below (pinned);
                    stick ();
    			} else {
    			    pinned = false;
                    set_keep_below (pinned);
                    applet_button.get_style_context().remove_class("rotated");
    			    unstick ();
                }
            });

            label = new Notejot.EditableLabel (this.title_name);
            header.set_custom_title(label);
            header.pack_end (applet_button);
            this.set_titlebar(header);

            actionbar = new Gtk.ActionBar ();
            actionbar.get_style_context().add_class("notejot-bar");
            create_actionbar ();
            create_app_menu ();

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.set_size_request (330,270);

            buffer = new Gtk.SourceBuffer (null);
            buffer.set_highlight_matching_brackets (false);
            view = new Gtk.SourceView.with_buffer (buffer);
            view.bottom_margin = 10;
            view.buffer.text = this.content;
            view.get_style_context().add_class("notejot-view");
            view.expand = true;
            view.left_margin = 10;
            view.margin = 2;
            view.right_margin = 10;
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            view.top_margin = 10;
            scrolled.add (view);
            this.show_all();

            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.expand = true;
            grid.add (scrolled);
            grid.add (actionbar);
            grid.show_all ();
            this.add (grid);

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

            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        action_undo ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK + Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        action_redo ();
                    }
                }
                return false;
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
            style = (N_("""
                @define-color textColorPrimary #323232;

                .mainwindow-%d {
                    background-color: %s;
                }

                .mainwindow-%d undershoot.top {
                    background:
                        linear-gradient(
                            %s 0%,
                            alpha(%s, 0) 50%
                        );
                }
                
                .mainwindow-%d undershoot.bottom {
                    background:
                        linear-gradient(
                            alpha(%s, 0) 50%,
                            %s 100%
                        );
                }

                .notejot-view text selection {
                    color: shade(%s, 1.88);
                    background-color: %s;
                }

                entry.flat {
                    background: transparent;
                }

                .window-%d .notejot-title image,
                .window-%d .notejot-label {
                    color: %s;
                    box-shadow: none;
                }

                .window-%d .notejot-bar {
                    color: %s;
                    background-color: %s;
                    border-top-color: %s;
                    box-shadow: none;
                    background-image: none;
                    padding: 3px;
                }

                .window-%d .notejot-bar image {
                    color: %s;
                    padding: 3px;
                    box-shadow: none;
                    background-image: none;
                }

                .window-%d .notejot-view,
                .window-%d .notejot-view text,
                .window-%d .notejot-title {
                    background-color: %s;
                    background-image: none;
                    border-bottom-color: %s;
                    font-weight: 500;
                    font-size: 1.2em;
                    color: shade(%s, 0.77);
                    box-shadow: none;
                }

                .window-%d .rotated > widget > box > image {
                    -gtk-icon-transform: rotate(90deg);
                }

                .color-button {
                    border-radius: 50%;
                    background-image: none;
                    border: 1px solid alpha(@BLACK_300, 0.25);
                    box-shadow:
                        inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                        inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                        0 1px 0 0 alpha (@bg_highlight_color, 0.3);
                }

                .color-button:hover,
                .color_button:focus {
                    border: 1px solid @BLACK_300;
                }

                .color-slate {
                    background-color: #a5b3bc;
                }

                .color-white {
                    background-color: #fafafa;
                }

                .color-red {
                    background-color: #ff8c82;
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

                .color-cocoa {
                    background-color: #a3907c;
                }
                """)).printf(uid, selected_color, uid, selected_color, selected_color, uid, selected_color, selected_color, selected_color, selected_color_text, uid, uid, selected_color_text, uid, selected_color_text, selected_color, selected_color, uid, selected_color_text, uid, uid, uid, selected_color, selected_color, selected_color_text, uid);

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

        private void create_actionbar () {
            var new_item = new Gtk.Button ();
            new_item.tooltip_text = (_("New note"));
            new_item.set_image (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            new_item.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW;

            delete_item = new Gtk.Button ();
            delete_item.tooltip_text = (_("Delete note"));
            delete_item.set_image (new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            delete_item.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_DELETE;

            actionbar.pack_start (new_item);
            actionbar.pack_start (delete_item);
        }

        private void create_app_menu () {
            var color_button_white = new Gtk.Button ();
            color_button_white.has_focus = false;
            color_button_white.halign = Gtk.Align.CENTER;
            color_button_white.height_request = 24;
            color_button_white.width_request = 24;
            color_button_white.tooltip_text = _("White");

            var color_button_white_context = color_button_white.get_style_context ();
            color_button_white_context.add_class ("color-button");
            color_button_white_context.add_class ("color-white");

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

            var color_button_cocoa = new Gtk.Button ();
            color_button_cocoa.has_focus = false;
            color_button_cocoa.halign = Gtk.Align.CENTER;
            color_button_cocoa.height_request = 24;
            color_button_cocoa.width_request = 24;
            color_button_cocoa.tooltip_text = _("Cocoa");

            var color_button_cocoa_context = color_button_cocoa.get_style_context ();
            color_button_cocoa_context.add_class ("color-button");
            color_button_cocoa_context.add_class ("color-cocoa");

            var color_button_slate = new Gtk.Button ();
            color_button_slate.has_focus = false;
            color_button_slate.halign = Gtk.Align.CENTER;
            color_button_slate.height_request = 24;
            color_button_slate.width_request = 24;
            color_button_slate.tooltip_text = _("Slate");

            var color_button_slate_context = color_button_slate.get_style_context ();
            color_button_slate_context.add_class ("color-button");
            color_button_slate_context.add_class ("color-slate");

            var color_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            color_button_box.pack_start (color_button_white, false, true, 0);
            color_button_box.pack_start (color_button_red, false, true, 0);
            color_button_box.pack_start (color_button_orange, false, true, 0);
            color_button_box.pack_start (color_button_yellow, false, true, 0);
            color_button_box.pack_start (color_button_green, false, true, 0);
            color_button_box.pack_start (color_button_blue, false, true, 0);
            color_button_box.pack_start (color_button_indigo, false, true, 0);
            color_button_box.pack_start (color_button_cocoa, false, true, 0);
            color_button_box.pack_start (color_button_slate, false, true, 0);

            var color_button_label = new Granite.HeaderLabel (_("Note Color"));

            var setting_grid = new Gtk.Grid ();
            setting_grid.margin = 12;
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

            color_button_white.clicked.connect (() => {
                this.color = "#F5F5F5";
                this.selected_color_text = "#666666";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_red.clicked.connect (() => {
                this.color = "#ff8c82";
                this.selected_color_text = "#7a0000";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_orange.clicked.connect (() => {
                this.color = "#ffc27d";
                this.selected_color_text = "#a62100";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_yellow.clicked.connect (() => {
                this.color = "#fff394";
                this.selected_color_text = "#ad5f00";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_green.clicked.connect (() => {
                this.color = "#d1ff82";
                this.selected_color_text = "#206b00";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_blue.clicked.connect (() => {
                this.color = "#8cd5ff";
                this.selected_color_text = "#002e99";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_indigo.clicked.connect (() => {
                this.color = "#aca9fd";
                this.selected_color_text = "#452981";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_cocoa.clicked.connect (() => {
                this.color = "#a3907c";
                this.selected_color_text = "#3d211b";
                update_theme();
                ((Application)this.application).update_storage();
            });

            color_button_slate.clicked.connect (() => {
                this.color = "#a5b3bc";
                this.selected_color_text = "#0e141f";
                update_theme();
                ((Application)this.application).update_storage();
            });

            actionbar.pack_end (app_button);
        }

        private void init_from_storage(Storage storage) {
            this.color = storage.color;
            this.selected_color_text = storage.selected_color_text;
            this.pinned = storage.pinned;
            this.content = storage.content;
            this.move((int)storage.x, (int)storage.y);
            if ((int)storage.w != 0 && (int)storage.h != 0) {
                this.resize ((int)storage.w, (int)storage.h);
            }
            this.title_name = storage.title;
            set_title (this.title_name);
        }

        private void action_new () {
            ((Application)this.application).create_note(null);
        }

        private void action_delete () {
            ((Application)this.application).remove_note(this);
            this.close ();
        }

        private void action_undo () {
            buffer.undo ();
        }

        private void action_redo () {
            buffer.redo ();
        }

        public Storage get_storage_note() {
            int x, y, w, h;
            string color = this.color;
            string selected_color_text = this.selected_color_text;
            bool pinned = this.pinned;
            Gtk.TextIter start,end;
            view.buffer.get_bounds (out start, out end);
            this.content = view.buffer.get_text (start, end, true);
            this.title_name = label.title.get_label ();
            set_title (this.title_name);

            this.get_position (out x, out y);
            this.get_size (out w, out h);

            return new Storage.from_storage(x, y, w, h, color, selected_color_text, pinned, content, title_name);
        }

#if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
#else
        protected bool match_keycode (int keyval, uint code) {
#endif
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }

            return false;
        }

        public override bool delete_event (Gdk.EventAny event) {
            int x, y;
            this.get_position (out x, out y);
            Notejot.Application.gsettings.set_int("window-x", x);
            Notejot.Application.gsettings.set_int("window-y", y);
            return false;
        }
    }
}
