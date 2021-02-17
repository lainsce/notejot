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
    public class Widgets.MoveToDialog : Hdy.Window {
        public unowned MainWindow win { get; construct; }

        public signal void clicked ();

        public GLib.ListStore notebookstore;
        private Hdy.ActionRow actionrow;

        [GtkChild]
        public Gtk.ListBox notebook_listbox;
        [GtkChild]
        public Gtk.Button cancel_button;
        [GtkChild]
        public Gtk.Button move_button;

        public MoveToDialog (MainWindow win) {
            Object (win: win);
            set_transient_for (win);
            this.show_all ();

            notebook_listbox.bind_model (win.notebookstore, item => make_item (win, item));
            notebook_listbox.set_selection_mode (Gtk.SelectionMode.SINGLE);

            notebook_listbox.row_selected.connect ((selected_row) => {
                move_button.sensitive = true;
            });

            move_button.clicked.connect (() => {
                uint i, n = win.notebookstore.get_n_items ();
                for (i = 0; i < n; i++) {
                    var item = win.notebookstore.get_item (i);

                    win.settingmenu.controller.log.notebook = ((Notebook)item).title;
                    win.settingmenu.controller.notebooklabel.label = ((Notebook)item).title;
                }
                this.close ();
            });

            cancel_button.clicked.connect (() => {
                this.close ();
            });
        }

        public Hdy.ActionRow make_item (MainWindow win, GLib.Object item) {
            actionrow = new Hdy.ActionRow ();
            actionrow.set_title (((Notebook)item).title);

            return actionrow;
        }

        public void make_notebook (string title) {
            var nb = new Notebook ();
            nb.title = title;

            notebookstore.append(nb);
        }
    }
}
