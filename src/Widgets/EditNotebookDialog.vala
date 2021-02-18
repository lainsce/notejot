/*
* Copyright (C) 2017-2021 Lains
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
    public class Notebook : Object {
        public string title { get; set; }
    }

    [GtkTemplate (ui = "/io/github/lainsce/Notejot/edit_notebooks.ui")]
    public class Widgets.EditNotebooksDialog : Hdy.Window {
        public unowned MainWindow win { get; construct; }
        public unowned Notebook notebook { get; construct; }

        public signal void clicked ();

        [GtkChild]
        public Gtk.Entry notebook_name_entry;
        [GtkChild]
        public Gtk.Button notebook_add_button;
        [GtkChild]
        public Gtk.ListBox notebook_listbox;

        public EditNotebooksDialog (MainWindow win) {
            Object (win: win);
            set_transient_for (win);

            notebook_add_button.sensitive = false;

            notebook_listbox.bind_model (win.notebookstore, item => make_item (win, item));
            notebook_listbox.set_selection_mode (Gtk.SelectionMode.NONE);

            notebook_name_entry.notify["text"].connect (() => {
                if (notebook_name_entry.get_text () != "") {
                    notebook_add_button.sensitive = true;
                } else {
                    notebook_add_button.sensitive = false;
                }
            });

            notebook_add_button.clicked.connect (() => {
                var nb = new Notebook ();
                nb.title = notebook_name_entry.text;

                win.notebookstore.append (nb);
                win.tm.save_notebooks.begin (win.notebookstore);
            });
        }

        public Hdy.ActionRow make_item (MainWindow win, GLib.Object item) {
            var actionrow = new Hdy.ActionRow ();
            actionrow.set_title (((Notebook)item).title);

            var ar_delete_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("window-close-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Remove notebook")),
                visible = true,
                valign = Gtk.Align.CENTER
            };
            ar_delete_button.get_style_context ().add_class ("flat");
            ar_delete_button.get_style_context ().add_class ("circular");

            ar_delete_button.clicked.connect (() => {
                uint i, n = win.notebookstore.get_n_items ();
                for (i = 0; i < n; i++) {
                    var im = win.notebookstore.get_item (i);
                    if (actionrow.get_title () == ((Notebook)im).title) {
                        win.notebookstore.remove (i);
                    }
                }
            });

            actionrow.add (ar_delete_button);

            return actionrow;
        }
    }
}
