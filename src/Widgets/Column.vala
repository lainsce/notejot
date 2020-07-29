namespace Notejot {
    public class Widgets.Column : Gtk.ListBox {
        private MainWindow win;

        public Column (MainWindow win) {
            var no_files = new Gtk.Label (_("No notes…")) {
                halign = Gtk.Align.CENTER
            };
            no_files.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            no_files.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            no_files.show_all ();

            this.win = win;
            this.expand = true;
            this.activate_on_single_click = true;
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            this.set_sort_func (list_sort);
            this.set_placeholder (no_files);

            this.row_selected.connect ((row) => {
                if (win.noteview.editablelabel != null) {
                    win.noteview.editablelabel.text = ((Widgets.Note)row).title;
                    win.noteview.textfield.text = ((Widgets.Note)row).contents;
                    win.noteview.textfield.update_html_view ();
                }
            });

            this.show_all ();
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