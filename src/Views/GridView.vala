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
    public class Views.GridView : Gtk.FlowBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public GridView (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.column_spacing = 30;
            this.row_spacing = 30;
            this.homogeneous = true;
            this.max_children_per_line = 3;
            this.activate_on_single_click = true;
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            
            is_modified = false;

            this.get_style_context ().add_class ("notejot-fgview");
            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                this.get_style_context ().add_class ("notejot-fgview-bg-dark");
                this.get_style_context ().remove_class ("notejot-fgview-bg");
            } else {
                this.get_style_context ().remove_class ("notejot-fgview-bg-dark");
                this.get_style_context ().add_class ("notejot-fgview-bg");
            }

            Notejot.Application.gsettings.changed["dark-mode"].connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    this.get_style_context ().add_class ("notejot-fgview-bg-dark");
                    this.get_style_context ().remove_class ("notejot-fgview-bg");
                } else {
                    this.get_style_context ().remove_class ("notejot-fgview-bg-dark");
                    this.get_style_context ().add_class ("notejot-fgview-bg");
                }
            });

            var provider2 = new Gtk.CssProvider ();
            string res1 = "\"resource:///com/github/lainsce/notejot/image/bg1.png\"";
            string res2 = "\"resource:///com/github/lainsce/notejot/image/bg2.png\"";
            string css = """
                .notejot-fgview-bg {
                    background-image: url(%s);
                    background-repeat: repeat;
                }
                .notejot-fgview-bg-dark {
                    background-image: url(%s);
                    background-repeat: repeat;
                }
             """.printf(res1, res2);
             try {
                provider2.load_from_data(css, -1);
             } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
             }
             Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider2, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            this.show_all ();
        }

        public void new_taskbox (MainWindow win, string title, string contents, string color) {
            var taskbox = new Widgets.TaskBox (win, title, contents, color);
            insert (taskbox, -1);
            win.tm.save_notes.begin ();
            is_modified = true;
        }

        public Gee.ArrayList<Gtk.FlowBoxChild> get_tasks () {
            var tasks = new Gee.ArrayList<Gtk.FlowBoxChild> ();
            foreach (Gtk.Widget item in this.get_children ()) {
                tasks.add ((Gtk.FlowBoxChild)item);
            }
            return tasks;
        }
    }
}