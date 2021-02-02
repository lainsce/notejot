/*
* Copyright (C) 2017-2021 Lains
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
    public class Widgets.Note : Hdy.ActionRow {
        private MainWindow win;
        public Widgets.TextField textfield;
        public Widgets.EditableLabel editablelabel;
        private static int uid_counter;
        public int uid;
        public new string title;
        public new string subtitle;
        public string text;
        public string color;
        private Gtk.CssProvider css_provider;

        public Note (MainWindow win, string title, string subtitle, string text, string color) {
            this.win = win;
            this.uid = uid_counter++;
            this.title = title;
            this.subtitle = subtitle;
            this.text = text;

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("", Gtk.IconSize.SMALL_TOOLBAR);
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            add_prefix (icon);

            set_title (this.title);
            set_subtitle (this.subtitle);

            this.show_all ();
            this.get_style_context ().add_class ("notejot-sidebar-box");

            update_theme (color);

            textfield = new Widgets.TextField (win);
            var text_scroller = new Gtk.ScrolledWindow (null, null);
            text_scroller.vexpand = true;
            text_scroller.add(textfield);
            textfield.text = this.text;
            textfield.controller = this;
            textfield.update_html_view.begin ();

            var titlelabel = new Widgets.EditableLabel (win, this.title);
            titlelabel.get_style_context ().add_class ("notejot-label-%d".printf(uid));
            titlelabel.halign = Gtk.Align.START;
            titlelabel.margin_top = 20;
            titlelabel.title.get_style_context ().add_class ("title-1");

            var subtitlelabel = new Widgets.EditableLabel (win, this.subtitle);
            subtitlelabel.halign = Gtk.Align.START;
            subtitlelabel.get_style_context ().add_class ("notejot-label-%d".printf(uid));
            subtitlelabel.title.get_style_context ().add_class ("title-3");

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            sep.margin_top = 12;

            var formatbar = new Widgets.FormatBar (win);
            formatbar.controller = textfield;

            var note_grid = new Gtk.Grid ();
            note_grid.column_spacing = 12;
            note_grid.attach (titlelabel, 0, 0);
            note_grid.attach (subtitlelabel, 0, 1);
            note_grid.attach (sep, 0, 2);
            note_grid.attach (text_scroller, 0, 3);
            note_grid.attach (formatbar, 0, 4);
            note_grid.show_all ();

            win.main_stack.add_named (note_grid, "textfield-%d".printf(uid));
            note_grid.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            titlelabel.changed.connect (() => {
               set_title (titlelabel.text);
               this.title = titlelabel.text;
               win.tm.save_notes.begin ();
            });

            subtitlelabel.changed.connect (() => {
               set_subtitle (subtitlelabel.text);
               this.subtitle = subtitlelabel.text;
               win.tm.save_notes.begin ();
            });

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                icon.get_style_context ().add_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                titlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                subtitlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                note_grid.get_style_context ().add_class ("notejot-stack-dark-%d".printf(uid));
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                icon.get_style_context ().remove_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                titlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                subtitlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                note_grid.get_style_context ().remove_class ("notejot-stack-dark-%d".printf(uid));
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                    icon.get_style_context ().add_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                    titlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                    subtitlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                    note_grid.get_style_context ().add_class ("notejot-stack-dark-%d".printf(uid));
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                    icon.get_style_context ().remove_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                    titlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                    subtitlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                    note_grid.get_style_context ().remove_class ("notejot-stack-dark-%d".printf(uid));
                }
            });
        }

        public void destroy_item () {
            this.dispose ();
            css_provider.dispose ();
        }

        public void select_item () {
            if (win.main_stack != null) {
                win.main_stack.set_visible_child_name ("textfield-%d".printf(uid));
            }
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                border: 1px solid alpha(black, 0.25);
                background: %s;
                border-radius: 50px;
            }
            .notejot-sidebar-dbg-dark-%d {
                border: 1px solid alpha(black, 0.25);
                background: shade(%s, 0.8);
                border-radius: 50px;
            }
            .notejot-label-%d {
                background: mix(%s, @theme_base_color, 0.8);
            }
            .notejot-label-dark-%d {
                background: mix(%s, @theme_base_color, 0.8);
            }
            .notejot-stack-%d {
                background: mix(%s, @theme_base_color, 0.8);
            }
            .notejot-stack-dark-%d {
                background: mix(%s, @theme_base_color, 0.8);
            }
            """)).printf(uid, color, uid, color, uid, color, uid, color, uid, color, uid, color);

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
            win.tm.save_notes.begin ();
        }
    }
}
