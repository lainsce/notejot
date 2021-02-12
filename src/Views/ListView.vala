namespace Notejot {
    public class Views.ListView : Gtk.ListBox {
        private MainWindow win;
        Gtk.GestureMultiPress press;
        public bool is_modified {get; set; default = false;}

        public ListView (MainWindow win) {
            this.win = win;
            this.vexpand = true;
            is_modified = false;
            set_sort_func (list_sort);
            this.show_all ();
            this.set_selection_mode (Gtk.SelectionMode.SINGLE);
            this.set_activate_on_single_click (true);

            this.row_selected.connect ((selected_row) => {
                win.leaflet.set_visible_child (win.grid);
                win.settingmenu.visible = true;

                if (((Widgets.Note)selected_row) != null) {
                    win.titlebar.pack_end (win.settingmenu);
                    ((Widgets.Note)selected_row).textfield.grab_focus ();
                    ((Widgets.Note)selected_row).select_item ();
                    win.settingmenu.controller = ((Widgets.Note)selected_row);
                } else {
                    win.titlebar.remove (win.settingmenu);
                }
            });

            this.events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
            this.button_release_event.connect ((event) => {
                if (event.type == Gdk.EventType.BUTTON_RELEASE && event.button == 3) {
                    if (((Widgets.Note)this.get_selected_row()) != null) {
                        var popover = new Widgets.NoteMenuPopover ();
                        ((Widgets.Note)this.get_selected_row()).popover_listener (popover);

                        popover.set_relative_to (((Widgets.Note)this.get_selected_row()));
                        popover.popup ();
                    }
                }
                return true;
            });

            press = new Gtk.GestureMultiPress (this);
            press.set_button (Gdk.BUTTON_SECONDARY);
            press.pressed.connect ((gesture, n_press, x, y) => {
                Gtk.Widget menu_row;
                var row = this.get_row_at_y ((int)y);
                var popover = new Widgets.NoteMenuPopover ();
                ((Widgets.Note)row).popover_listener (popover);

                popover.set_relative_to (((Widgets.Note)row));
                popover.popup ();
                menu_row = row;
            });
        }

        public GLib.List<unowned Widgets.Note> get_rows () {
            return (GLib.List<unowned Widgets.Note>) this.get_children ();
        }

        public void clear_column () {
            foreach (Gtk.Widget item in this.get_children ()) {
                item.destroy ();
            }
            win.tm.save_notes.begin ();
        }

        public async void new_taskbox (MainWindow win, string title, string contents, string text, string color) {
            var taskbox = new Widgets.Note (win, title, contents, text, color);
            insert (taskbox, -1);
            win.tm.save_notes.begin ();
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
