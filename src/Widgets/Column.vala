namespace Notejot {
    public class Widgets.Column : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public Column (MainWindow win) {
            var no_files = new Gtk.Label (_("No notes…"));
            no_files.halign = Gtk.Align.CENTER;
            var no_files_style_context = no_files.get_style_context ();
            no_files_style_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            no_files_style_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            no_files.show_all ();

            this.win = win;
            this.vexpand = true;
            is_modified = false;
            activate_on_single_click = true;
            selection_mode = Gtk.SelectionMode.SINGLE;
            set_sort_func (list_sort);
            set_placeholder (no_files);

            this.row_selected.connect ((row) => {
                if (((Widgets.TaskBox)row) != null) {
                    win.textview.get_buffer ().text = ((Widgets.TaskBox)row).contents;
                    win.editablelabel.text = ((Widgets.TaskBox)row).title;
                    win.tm.save_notes ();
                }
            });

            this.show_all ();
        }

        public void add_task (string title, string contents, string color) {
            var taskbox = new Widgets.TaskBox (win, title, contents, color);
            this.insert (taskbox, 1);
            this.select_row (taskbox);
            win.tm.save_notes ();
            this.is_modified = true;
        }

        public GLib.List<unowned TaskBox> get_rows () {
            return (GLib.List<unowned TaskBox>) this.get_children ();
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

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }
    }
}
