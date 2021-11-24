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
        public NotebookViewModel nbview_model {get; set;}
        public LogViewModel view_model {get; set;}

        public signal void clicked ();

        Notebook? _notebook;
        public Notebook? notebook {
            get { return _notebook; }
            set {
                if (value == _notebook)
                    return;

                _notebook = value;
            }
        }

        Log? _note;
        public Log? note {
            get { return _note; }
            set {
                if (value == _note)
                    return;

                _note = value;
            }
        }

        [GtkChild]
        public unowned Gtk.Button cancel_button;
        [GtkChild]
        public unowned Gtk.Button remove_notebook_button;
        [GtkChild]
        public unowned Gtk.Button move_button;

        public MoveToDialog (MainWindow win, NotebookViewModel nbview_model, LogViewModel view_model) {
            Object (
                nbview_model: nbview_model,
                view_model: view_model
            );
            this.win = win;
            this.set_modal (true);
            this.set_transient_for (win);

            remove_notebook_button.clicked.connect (() => {
                this.dispose ();
            });

            cancel_button.clicked.connect (() => {
                this.dispose ();
            });
        }

        [GtkCallback]
        void on_move_notebook_requested () {
            if (notebook != null)
                move_button.sensitive = true;
                string nb = notebook.title;
                view_model.update_notebook (note, nb);
        }
    }
}
