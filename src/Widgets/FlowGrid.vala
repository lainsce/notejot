namespace Notejot {
    public class Widgets.FlowGrid : Gtk.FlowBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public FlowGrid (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.homogeneous = true;
            activate_on_single_click = true;
            selection_mode = Gtk.SelectionMode.SINGLE;

            this.child_activated.connect ((item) => {
                if (item != null && win.editablelabel != null && win.stack != null) {
                    win.editablelabel.text = ((Widgets.TaskBox)item.get_child ()).title;
                    win.textview.text = ((Widgets.TaskBox)item.get_child ()).contents;
                    win.textview.update_html_view ();
                    win.stack.set_visible_child (win.note_view);
                    win.format_button.sensitive = true;
                }
            });

            this.get_style_context ().add_class ("notejot-lview");
            this.show_all ();
        }
    }
}