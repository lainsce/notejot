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
            this.get_style_context ().add_class ("notejot-view");

            var empty_state = new Hdy.StatusPage ();
            empty_state.visible = true;
            empty_state.icon_name = "user-trash-symbolic";
            empty_state.title = _("No Trash");
            empty_state.description = _("Trashed notes appear here.");

            this.set_placeholder (empty_state);
        }

        public void clear_column () {
            win.trashstore.remove_all ();
        }
    }
}
