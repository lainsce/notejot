namespace Notejot {
    public class Views.ListView : Object {
        private MainWindow win;
        Gtk.GestureClick press;

        public bool is_modified {get; set; default = false;}

        public string search_text = "";
        private int last_uid;

        public ListView (MainWindow win) {
            this.win = win;
            is_modified = false;

            win.listview.set_filter_func (do_filter_list);

            win.listview.row_selected.connect ((selected_row) => {
                win.leaflet.set_visible_child (win.grid);
                win.settingmenu.visible = true;

                if (((Widgets.Note)selected_row) != null) {
                    ((Widgets.Note)selected_row).textfield.grab_focus ();
                    ((Widgets.Note)selected_row).select_item ();
                    win.titlebar.get_style_context ().remove_class (@"notejot-action-$last_uid");

                    last_uid = ((Widgets.Note)selected_row).uid;
                    win.sm.controller = ((Widgets.Note)selected_row);
                    win.titlebar.get_style_context ().add_class (@"notejot-action-$last_uid");
                } else {
                    win.titlebar.get_style_context ().remove_class (@"notejot-action-$last_uid");
                }
            });

            press = new Gtk.GestureClick ();
            win.listview.add_controller (press);
            press.button = Gdk.BUTTON_SECONDARY;

            press.pressed.connect ((gesture, n_press, x, y) => {
                if (n_press > 1) {
                    press.set_state (Gtk.EventSequenceState.DENIED);
                    return;
                }

                var row = win.listview.get_row_at_y ((int)y);

                if (row == null) {
                    press.set_state (Gtk.EventSequenceState.DENIED);
                    return;
                }

                var popover = new Widgets.NoteMenuPopover ();
                popover.set_parent (win);
                ((Widgets.Note)row).popover_listener (popover);

                Gtk.Allocation allocation;
                row.get_allocation (out allocation);

                popover.set_pointing_to (allocation);
                popover.set_offset (0, 40); // Needed so that the popover doesn't show above the list widget
                popover.popup ();
                popover.set_autohide (true);

                press.set_state (Gtk.EventSequenceState.CLAIMED);
            });
        }

        public void set_search_text (string search_text) {
            this.search_text = search_text;
            win.listview.invalidate_filter ();
        }

        protected bool do_filter_list (Gtk.ListBoxRow row) {
            if (search_text.length > 0) {
                return ((Widgets.Note)row).get_title ().down ().contains (search_text.down ());
            }

            return true;
        }

        public GLib.List<unowned Widgets.Note> get_rows () {
            return (GLib.List<unowned Widgets.Note>) win.notestore.get_n_items ();
        }
    }
}
