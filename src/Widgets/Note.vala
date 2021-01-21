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
    public class Widgets.Note : Gtk.ListBoxRow {
        private MainWindow win;
        public Widgets.TextField textfield;
        public Widgets.EditableLabel editablelabel;
        private Gtk.Label label;
        private Gtk.Label label2;
        private static int uid_counter;
        public int uid;
        public string title;
        public string subtitle;
        public string text;
        public string color;

        public Note (MainWindow win, string title, string subtitle, string text, string color) {
            this.win = win;
            this.uid = uid_counter++;
            this.title = title;
            this.subtitle = subtitle;
            this.text = text;
            this.margin_bottom = 6;

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("", Gtk.IconSize.SMALL_TOOLBAR);
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            label = new Gtk.Label (this.title);
            label.halign = Gtk.Align.START;
            label.ellipsize = Pango.EllipsizeMode.END;
            label.max_width_chars = 16;
            label.get_style_context ().add_class ("title-4");
            label2 = new Gtk.Label (this.subtitle);
            label2.halign = Gtk.Align.START;
            label2.ellipsize = Pango.EllipsizeMode.END;
            label2.max_width_chars = 19;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 6;
            grid.attach (icon, 0, 0, 1, 2);
            grid.attach (label, 1, 0);
            grid.attach (label2, 1, 1);
            grid.show_all ();

            this.show_all ();
            this.add (grid);
            this.get_style_context ().add_class ("notejot-sidebar-box");

            update_theme (color);

            textfield = new Widgets.TextField (win);
            textfield.get_style_context ().add_class ("notejot-tview-%d".printf(uid));
            var text_scroller = new Gtk.ScrolledWindow (null, null);
            text_scroller.vexpand = true;
            text_scroller.add(textfield);
            textfield.get_buffer ().set_text (this.text);

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
            sep.margin_start = sep.margin_end = 40;

            var note_grid = new Gtk.Grid ();
            note_grid.column_spacing = 12;
            note_grid.row_spacing = 6;
            note_grid.attach (titlelabel, 0, 0);
            note_grid.attach (subtitlelabel, 0, 1);
            note_grid.attach (sep, 0, 2);
            note_grid.attach (text_scroller, 0, 3);
            note_grid.show_all ();

            win.main_stack.add_named (note_grid, "textfield-%d".printf(uid));
            note_grid.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            titlelabel.changed.connect (() => {
               label.label = titlelabel.text;
               this.title = titlelabel.text;
               win.titlebar.title = titlelabel.text;
               win.tm.save_notes ();
            });

            subtitlelabel.changed.connect (() => {
               label2.label = subtitlelabel.text;
               this.subtitle = subtitlelabel.text;
               win.tm.save_notes ();
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
            this.destroy ();
        }

        public void select_item () {
            win.main_stack.set_visible_child_name ("textfield-%d".printf(uid));
            win.titlebar.title = this.title;
        }

        public void update_theme(string? color) {
            var css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                border: 1px solid alpha(black, 0.25);
                background: %s;
                border-radius: 50px;
                margin-left: 12px;
            }
            .notejot-sidebar-dbg-dark-%d {
                border: 1px solid alpha(black, 0.25);
                background: shade(%s, 0.8);
                border-radius: 50px;
                margin-left: 12px;
            }
            .notejot-tview-%d text {
                background: mix(%s, @theme_base_color, 0.95);
                color: shade(%s, 0.3);
            }
            .notejot-tview-dark-%d text {
                background: mix(%s, @theme_base_color, 0.95);
                color: shade(%s, 1.25);
            }
            .notejot-label-%d {
                background: mix(%s, @theme_base_color, 0.95);
                color: shade(%s, 0.3);
            }
            .notejot-label-dark-%d {
                background: mix(%s, @theme_base_color, 0.95);
                color: shade(%s, 1.25);
            }
            .notejot-stack-%d {
                background: mix(%s, @theme_base_color, 0.95);
                color: shade(%s, 0.3);
            }
            .notejot-stack-dark-%d {
                background: mix(%s, @theme_base_color, 0.95);
                color: shade(%s, 0.3);
            }
            """)).printf(uid, color, uid, color, uid, color, color, uid, color,
                         color, uid, color, color, uid, color, color, uid, color,
                         color, uid, color, color);

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
