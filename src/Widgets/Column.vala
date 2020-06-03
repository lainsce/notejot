namespace Notejot {
    public class Widgets.Column : Gtk.Grid {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public Column (MainWindow win) {
            this.win = win;
            this.row_spacing = 12;
            this.margin = 6;
            is_modified = false;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.show_all ();
        }

        public void clear_column () {
            foreach (Gtk.Widget item in this.get_children ()) {
                item.destroy ();
            }
            win.tm.save_notes ();
        }

        public Gee.ArrayList<TaskBox> get_tasks () {
            var tasks = new Gee.ArrayList<TaskBox> ();
            foreach (Gtk.Widget item in this.get_children ()) {
	            tasks.add ((TaskBox)item);
            }
            return tasks;
        }
    }
}
