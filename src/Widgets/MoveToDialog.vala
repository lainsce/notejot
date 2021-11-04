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
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/move_to_dialog.ui")]
    public class Widgets.MoveToDialog : Adw.Window {
        public unowned MainWindow win = null;

        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.ListBox notebook_listbox;
        [GtkChild]
        public unowned Gtk.Button cancel_button;
        [GtkChild]
        public unowned Gtk.Button remove_notebook_button;
        [GtkChild]
        public unowned Gtk.Button move_button;

        public MoveToDialog (MainWindow win) {
            this.win = win;
            this.set_modal (true);
            this.set_transient_for (win);

            notebook_listbox.bind_model (win.notebookstore, item => make_item (win, item));
            notebook_listbox.set_selection_mode (Gtk.SelectionMode.SINGLE);

            if (win.sm.controller.log.notebook == "<i>" + _("No Notebook") + "</i>") {
                remove_notebook_button.sensitive = false;
            } else {
                remove_notebook_button.sensitive = true;
            }

            remove_notebook_button.clicked.connect (() => {
                if (win.sm.controller.log != null) {
                    win.sm.controller.log.notebook = "<i>" + _("No Notebook") + "</i>";
                }

                this.dispose ();
            });

            cancel_button.clicked.connect (() => {
                this.dispose ();
            });
        }

        public Adw.ActionRow make_item (MainWindow win, GLib.Object item) {
            var actionrow = new Adw.ActionRow ();
            actionrow.set_title (((Notebook)item).title);

            notebook_listbox.row_selected.connect ((selected_row) => {
                move_button.sensitive = true;

                move_button.clicked.connect (() => {
                    uint i, n = win.notebookstore.get_n_items ();
                    for (i = 0; i < n; i++) {
                        var im = win.notebookstore.get_item (i);

                        if (((Adw.ActionRow)selected_row).get_title () == ((Notebook)im).title) {
                            if (win.sm.controller.log != null) {
                                win.sm.controller.log.notebook = ((Notebook)im).title;
                            }
                        }
                    }
                    this.dispose ();
                });
            });

            return actionrow;
        }
    }
}
