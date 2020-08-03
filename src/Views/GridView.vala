namespace Notejot {
    public class Views.GridView : Gtk.Grid {
        public MainWindow win;
        public Widgets.FlowGrid flowgrid;

        public GridView (MainWindow win) {
            this.win = win;

            flowgrid = new Widgets.FlowGrid (win);

            var flowgrid_scroller = new Gtk.ScrolledWindow (null, null);
            flowgrid_scroller.add (flowgrid);

            this.add (flowgrid_scroller);
            this.show_all ();
        }
    }
}