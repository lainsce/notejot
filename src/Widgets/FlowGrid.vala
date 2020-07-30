namespace Notejot {
    public class Widgets.FlowGrid : Gtk.FlowBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public FlowGrid (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.homogeneous = true;

            this.get_style_context ().add_class ("notejot-lview");
            this.show_all ();
        }
    }
}