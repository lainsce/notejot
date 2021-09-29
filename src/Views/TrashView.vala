namespace Notejot {
    public class Views.TrashView : Object {
        public bool is_modified {get; set; default = false;}
        private MainWindow win = null;
        public int last_uid;

        public TrashView (MainWindow win) {
            this.win = win;
            is_modified = false;

            win.trashview.row_selected.connect ((selected_row) => {
                win.leaflet.set_visible_child (win.grid);
                win.settingmenu.visible = true;

                if (((Widgets.TrashedNote)selected_row) != null) {
                    ((Widgets.TrashedNote)selected_row).textfield.grab_focus ();
                    ((Widgets.TrashedNote)selected_row).select_item ();

                    win.titlebar.get_style_context ().remove_class (@"notejot-action-trash-$last_uid");

                    last_uid = ((Widgets.TrashedNote)selected_row).tuid;
                    win.sm.controller = ((Widgets.Note)selected_row);
                    win.titlebar.get_style_context ().add_class (@"notejot-action-trash-$last_uid");

                    win.titlebar.get_style_context ().remove_class ("notejot-empty-title");
                } else {
                    win.titlebar.get_style_context ().remove_class (@"notejot-action-trash-$last_uid");

                    win.titlebar.get_style_context ().add_class ("notejot-empty-title");
                }
            });
        }

        public void clear_column () {
            win.trashstore.remove_all ();
        }
    }
}
