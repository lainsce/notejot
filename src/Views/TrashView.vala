namespace Notejot {
    public class Views.TrashView : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public TrashView (MainWindow win) {
            this.win = win;
            this.vexpand = true;
            is_modified = false;
            set_sort_func (list_sort);
            this.show_all ();
        }

        public void new_taskbox (MainWindow win, string title, string contents, string text, string color) {
            var taskbox = new Widgets.SidebarItem (win, title, contents, text, color);
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
