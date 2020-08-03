/*
* Copyright (c) 2017-2020 Lains
*
* This program is free software; you can redistribute it and/or
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
    public class Views.NoteView : Gtk.Grid {
        public MainWindow win;
        public Widgets.Toolbar toolbar;
        public Widgets.EditableLabel editablelabel;
        public Widgets.TextField textfield;

        public NoteView (MainWindow win) {
            this.win = win;

            textfield = new Widgets.TextField (win);            
            toolbar = new Widgets.Toolbar (win, this);
            editablelabel = new Widgets.EditableLabel (win, "");

            editablelabel.changed.connect (() => {
                win.grid_view.flowgrid.selected_foreach ((item, child) => {
                    ((Widgets.TaskBox)child.get_child ()).task_label.set_label(editablelabel.title.get_label ());
                    ((Widgets.TaskBox)child.get_child ()).sidebaritem.title = editablelabel.title.get_label ();
                });
                win.tm.save_notes ();
            });

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                textfield.get_style_context ().add_class ("notejot-tview-dark");
                toolbar.toolbar.get_style_context ().add_class ("notejot-abar-dark");
                textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                toolbar.toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                textfield.get_style_context ().remove_class ("notejot-tview-dark");
                textfield.update_html_view ();
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                    textfield.get_style_context ().add_class ("notejot-tview-dark");
                    toolbar.toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                    toolbar.toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    textfield.get_style_context ().remove_class ("notejot-tview-dark");
                    textfield.update_html_view ();
                }
            });

            win.sidebar.sidebar_button.clicked.connect (() => {
                if (win.stack.get_visible_child () == this) {
                    win.stack.set_visible_child (win.grid_view);
                }
            });

            this.orientation = Gtk.Orientation.VERTICAL;
            this.add (toolbar);
            this.add (editablelabel);
            this.add (textfield);
            this.show_all ();
        }
    }
}