/*
* Copyright (C) 2017-2020 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
    public class Widgets.TrashedTask : Gtk.Grid {
        private MainWindow win;
        public Widgets.NoteWindow notewindow;
        public Widgets.SidebarItem sidebaritem;
        public Widgets.TaskLine taskline;
        public Widgets.TaskContentView task_contents;
        public Gtk.ActionBar bar;
        public Gtk.Grid main_grid;
        public Gtk.Label task_label;

        private static int uid_counter;
        public int uid;
        public string color = "#FFE16B";
        public string title = "New Note…";
        public string contents = "Write a new note…";

        public TrashedTask (MainWindow win, string? title, string? contents, string? color) {
            this.win = win;
            this.uid = uid_counter++;
            this.title = title;
            this.contents = contents;
            this.color = color;
            this.opacity = 0.66;

            bar = new Gtk.ActionBar ();
            bar.get_style_context ().add_class ("notejot-bar");

            task_label = new Gtk.Label (this.title);
            task_label.halign = Gtk.Align.START;
            task_label.valign = Gtk.Align.CENTER;
            task_label.wrap = true;
            task_label.hexpand = true;
            task_label.max_width_chars = 24;
            task_label.margin_start = task_label.margin_end = 6;
            task_label.ellipsize = Pango.EllipsizeMode.END;

            task_contents = new Widgets.TaskContentView (win, this.contents, this.uid);
            task_contents.margin_bottom = 8;
            task_contents.update_html_view ();

            var task_contents_holder = new Gtk.ScrolledWindow (null, null);
            task_contents_holder.vexpand = true;
            task_contents_holder.add (task_contents);

            var recover_note_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("go-previous-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = _("Restore this note…")
            };

			recover_note_button.clicked.connect (() => {
                win.gridview.new_taskbox (win, this.title, this.contents, this.color);
                this.get_parent ().destroy ();
            });

            bar.pack_start (task_label);
            bar.pack_end (recover_note_button);

            update_theme (this.color);
            win.tm.save_notes ();

            this.set_size_request (200,200);
            this.get_style_context ().add_class ("notejot-note-trash");
            this.get_style_context ().add_class ("notejot-note-trash-%d".printf(uid));
            this.orientation = Gtk.Orientation.VERTICAL;
            this.halign = Gtk.Align.CENTER;
            this.valign = Gtk.Align.CENTER;
            this.row_spacing = 6;
            this.add (bar);
            this.add (task_contents_holder);
            this.expand = false;
            this.show_all ();

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                this.get_style_context ().add_class ("notejot-note-trash-dark-%d".printf(uid));
                task_contents.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                this.get_style_context ().remove_class ("notejot-note-trash-dark-%d".printf(uid));
                task_contents.update_html_view ();
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    this.get_style_context ().add_class ("notejot-note-trash-dark-%d".printf(uid));
                    task_contents.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    this.get_style_context ().remove_class ("notejot-note-trash-dark-%d".printf(uid));
                    task_contents.update_html_view ();
                }
            });
        }

        public void update_theme(string? color) {
            var css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-note-trash-%d {
                background-image: linear-gradient(to bottom, %s 35px, #F7F7F7 1px);
            }
            .notejot-note-trash-dark-%d {
                background-image: linear-gradient(to bottom, shade(%s, 0.8) 35px, #303030 1px);
            }
            """)).printf(uid, color, uid, color);

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

            this.color = color;
            win.tm.save_notes ();
        }
    }
}
