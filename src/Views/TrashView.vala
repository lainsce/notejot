namespace Notejot {
    public class Views.TrashView : Object {
        public bool is_modified {get; set; default = false;}
        private MainWindow win = null;

        public TrashView (MainWindow win) {
            this.win = win;
            is_modified = false;
        }

        public void clear_column () {
            win.trashstore.remove_all ();
        }
    }
}
