namespace Notejot {
    public class Widgets.NoteBox : Gtk.ListBoxRow {
        private MainWindow win;
        private int uid;
        private static int uid_counter;
        public string color = "#FFE16B";
        public string contents = "Write a new note…";
        public string title = "New Note…";

        public NoteBox (MainWindow win, string title, string contents, string color) {
            this.color = color;
            this.contents = contents;
            this.title = title;
            this.win = win;
            this.uid = uid_counter++;
            this.get_style_context ().add_class ("notejot-column-box");
            this.show_all ();
        }
    }
}