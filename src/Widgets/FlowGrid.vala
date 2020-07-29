namespace Notejot {
    public class Widgets.FlowGrid : Gtk.FlowBox {
        private MainWindow win;

        public FlowGrid (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.show_all ();
        }
    }
}