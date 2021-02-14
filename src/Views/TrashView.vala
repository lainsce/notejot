namespace Notejot {
    public class Views.TrashView : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public TrashView (MainWindow win) {
            this.win = win;
            this.vexpand = true;
            is_modified = false;
            this.show_all ();
            this.set_selection_mode (Gtk.SelectionMode.NONE);
        }

        public void clear_column () {
            win.trashstore.remove_all ();
        }
    }
}
