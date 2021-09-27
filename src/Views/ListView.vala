namespace Notejot {
    public class Views.ListView : Object {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}
        public string search_text = "";
        public string selected_notebook = "";
        public int last_uid;

        public ListView (MainWindow win) {
            this.win = win;
            is_modified = false;

            win.listview.set_filter_func (do_filter_list);
            win.listview.set_filter_func (do_filter_list_notebook);

            win.listview.row_selected.connect ((selected_row) => {
                win.leaflet.set_visible_child (win.grid);
                win.settingmenu.visible = true;

                if (((Widgets.Note)selected_row) != null) {
                    ((Widgets.Note)selected_row).textfield.grab_focus ();
                    ((Widgets.Note)selected_row).select_item ();
                    win.titlebar.get_style_context ().remove_class (@"notejot-action-$last_uid");

                    if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                        win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$last_uid");
                    } else {
                        win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$last_uid");
                    }

                    last_uid = ((Widgets.Note)selected_row).uid;
                    win.sm.controller = ((Widgets.Note)selected_row);
                    win.titlebar.get_style_context ().add_class (@"notejot-action-$last_uid");

                    if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                        win.titlebar.get_style_context ().add_class (@"notejot-action-dark-$last_uid");
                    } else {
                        win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$last_uid");
                    }
                    win.titlebar.get_style_context ().remove_class ("notejot-empty-title");
                } else {
                    win.titlebar.get_style_context ().remove_class (@"notejot-action-$last_uid");

                    if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                        win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$last_uid");
                    } else {
                        win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$last_uid");
                    }
                    win.titlebar.get_style_context ().add_class ("notejot-empty-title");
                }
            });
        }

        public void set_search_text (string st) {
            this.search_text = st;
            win.listview.invalidate_filter ();
        }

        public void set_selected_notebook (string sn) {
            this.selected_notebook = sn;
            win.listview.invalidate_filter ();
        }

        public string get_search_text () {
            return this.search_text;
        }

        public string get_selected_notebook () {
            return this.selected_notebook;
        }

        protected bool do_filter_list (Gtk.ListBoxRow row) {
            if (search_text != "") {
                return ((Widgets.Note)row).get_title ().down ().contains (search_text.down ());
            }

            return true;
        }

        protected bool do_filter_list_notebook (Gtk.ListBoxRow row) {
            if (selected_notebook != "") {
                return ((Widgets.Note)row).log.notebook.down ().contains (selected_notebook.down ());
            }

            return true;
        }

        public GLib.List<unowned Widgets.Note> get_rows () {
            return (GLib.List<unowned Widgets.Note>) win.notestore.get_n_items ();
        }
    }
}
