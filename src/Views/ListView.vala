namespace Notejot {
    public class Views.ListView : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public ListView (MainWindow win) {
            this.win = win;
            this.vexpand = true;
            is_modified = false;
            set_sort_func (list_sort);
            this.show_all ();
            this.set_selection_mode (Gtk.SelectionMode.SINGLE);

            this.row_selected.connect ((selected_row) => {
                foreach (var row in get_rows ()) {
                    win.settingmenu.controller = ((Widgets.Note)selected_row);
                    ((Widgets.Note)selected_row).select_item ();
                    win.leaflet.set_visible_child (win.grid);
                    win.settingmenu.visible = true;
                }
            });
        }

        public GLib.List<unowned Widgets.Note> get_rows () {
            return (GLib.List<unowned Widgets.Note>) this.get_children ();
        }

        public void clear_column () {
            foreach (Gtk.Widget item in this.get_children ()) {
                item.destroy ();
            }
            win.tm.save_notes ();
        }

        public void new_taskbox (MainWindow win, string title, string contents, string text, string color) {
            var taskbox = new Widgets.Note (win, title, contents, text, color);
            insert (taskbox, -1);
            win.tm.save_notes ();
            is_modified = true;
        }

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }
    }
}
