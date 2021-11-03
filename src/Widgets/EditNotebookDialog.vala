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
    public class Widgets.EditNotebooksDialog : Adw.Window {
        public unowned MainWindow win = null;
        public unowned Notebook notebook { get; construct; }

        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.Entry notebook_name_entry;
        [GtkChild]
        public unowned Gtk.Button notebook_add_button;
        [GtkChild]
        public unowned Gtk.ListBox notebook_listbox;

        public EditNotebooksDialog (MainWindow win) {
            this.win = win;
            this.set_modal (true);
            this.set_transient_for (win);

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

            notebook_name_entry.activate.connect (() => {
                var nb = new Notebook ();
                nb.title = notebook_name_entry.text;

                win.notebookstore.append (nb);
                win.tm.save_notebooks.begin (win.notebookstore);
                notebook_name_entry.set_text ("");
            });

            notebook_add_button.clicked.connect (() => {
                var nb = new Notebook ();
                nb.title = notebook_name_entry.text;

                win.notebookstore.append (nb);
                win.tm.save_notebooks.begin (win.notebookstore);
                notebook_name_entry.set_text ("");
            });
        }

        public Adw.ActionRow make_item (MainWindow win, GLib.Object item) {
            var actionrow = new Adw.ActionRow ();

            var notebook_entry = new Gtk.Entry ();
            notebook_entry.valign = Gtk.Align.CENTER;
            notebook_entry.hexpand = true;
            notebook_entry.set_text (((Notebook)item).title);
            actionrow.add_prefix (notebook_entry);

            uint x, y = win.notebookstore.get_n_items ();
            for (x = 0; x < y; x++) {
                var im = win.notebookstore.get_item (x);
                if (notebook_entry.get_text () == ((Notebook)im).title) {
                    notebook_entry.activate.connect (() => {
                        print("Changed Notebook name!\n");
                        string notebook_name = notebook_entry.get_text ();
                        ((Notebook)im).title == notebook_name;
                        win.tm.save_notebooks.begin (win.notebookstore);
                        uint i2, n2 = win.notestore.get_n_items ();
                        for (i2 = 0; i2 < n2; i2++) {
                            var item2 = win.notestore.get_item (i2);
                            if (notebook_entry.get_text () == ((Log)item2).notebook) {
                                ((Log)item2).notebook = notebook_name;
                            }
                        }
                    });
                }
            }


            var ar_delete_button = new Gtk.Button () {
                icon_name = "window-close-symbolic",
                tooltip_text = (_("Remove notebook")),
                valign = Gtk.Align.CENTER
            };
            ar_delete_button.get_style_context ().add_class ("flat");

            ar_delete_button.clicked.connect (() => {
                uint j, m = win.notebookstore.get_n_items ();
                for (j = 0; j < m; j++) {
                    var im = win.notebookstore.get_item (j);
                    if (notebook_entry.get_text () == ((Notebook)im).title) {
                        win.notebookstore.remove (j);
                        ((Notebook)im).title == "<i>" + _("No Notebook") + "</i>";
                        win.tm.save_notebooks.begin (win.notebookstore);

                        uint i2, n2 = win.notestore.get_n_items ();
                        for (i2 = 0; i2 < n2; i2++) {
                            var item2 = win.notestore.get_item (i2);

                            if (notebook_entry.get_text () == ((Log)item2).notebook) {
                                ((Log)item2).notebook = "<i>" + _("No Notebook") + "</i>";
                            }
                        }

                        uint i4, n4 = win.trashstore.get_n_items ();
                        for (i4 = 0; i4 < n4; i4++) {
                            var item4 = win.trashstore.get_item (i4);

                            if (notebook_entry.get_text () == ((TrashLog)item4).notebook) {
                                ((TrashLog)item4).notebook = "<i>" + _("No Notebook") + "</i>";
                                win.tm.save_trash_notes.begin (win.trashstore);
                            }
                        }
                    }
                }
            });

            actionrow.add_suffix (ar_delete_button);

            return actionrow;
        }
    }
}
