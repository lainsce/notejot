namespace Notejot {
    public class Widgets.Column : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public Column (MainWindow win) {
            var no_files = new Gtk.Label (_("No notes…")) {
                halign = Gtk.Align.CENTER
            };
            no_files.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            no_files.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            no_files.show_all ();

            this.win = win;
            this.expand = true;
            this.is_modified = false;
            this.activate_on_single_click = true;
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            this.set_sort_func (list_sort);
            this.set_placeholder (no_files);

            this.row_selected.connect ((row) => {
                if (((Widgets.NoteBox)row) != null && win.noteview.editablelabel != null) {
                    win.noteview.editablelabel.text = ((Widgets.NoteBox)row).title;
                    win.noteview.textfield.text = ((Widgets.NoteBox)row).contents;
                    win.noteview.textfield.update_html_view ();
                    win.noteview.visible = true;
                    win.welcomeview.visible = false;
                    win.listview.visible = false;
                    win.format_button.visible = true;
                    win.new_button.visible = false;
                }
            });

            this.show_all ();
        }

        public GLib.List<unowned NoteBox> get_rows () {
            return (GLib.List<unowned NoteBox>) this.get_children ();
        }

        public void clear_column () {
            foreach (Gtk.Widget item in this.get_children ()) {
                item.destroy ();
            }
            win.tm.save_notes ();
        }

        public Gee.ArrayList<NoteBox> get_tasks () {
            var tasks = new Gee.ArrayList<NoteBox> ();
            foreach (Gtk.Widget item in this.get_children ()) {
	            tasks.add ((NoteBox)item);
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