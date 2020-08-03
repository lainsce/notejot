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