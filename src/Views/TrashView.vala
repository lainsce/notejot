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
                win.settingmenu.popover = null;
                win.settingmenu.popover = win.sm.tnmpopover;

                if (((Widgets.TrashedNote)selected_row) != null) {
                    ((Widgets.TrashedNote)selected_row).textfield.grab_focus ();
                    ((Widgets.TrashedNote)selected_row).select_item ();
                    win.sm.tcontroller = ((Widgets.TrashedNote)selected_row);

                    win.formatbar.get_style_context ().remove_class (@"nw-formatbar-trash-$last_uid");
                    win.formatbar.set_sensitive (false);

                    last_uid = ((Widgets.Note)selected_row).uid;

                    win.formatbar.get_style_context ().add_class (@"nw-formatbar-trash-$last_uid");
                } else {
                    win.formatbar.get_style_context ().remove_class (@"nw-formatbar-trash-$last_uid");
                    win.formatbar.set_sensitive (true);
                }
            });
        }

        public void clear_column () {
            win.trashstore.remove_all ();
        }
    }
}
