namespace Notejot {
    public class Widgets.SidebarItem : Granite.Widgets.SourceList.Item {
        private MainWindow win;

        public string title {
            set {
                this.markup = value;
            }
        }

        public SidebarItem (MainWindow win, string title, string contents) {
            this.title = title;
            this.win = win;

            var icon = new ThemedIcon ("emblem-documents-symbolic");

            this.selectable = true;
            this.icon = icon;
            this.tooltip = (_("This is a note."));

            this.activated.connect (() => {
                if (this != null && win.editablelabel != null && win.stack != null) {
                    win.editablelabel.text = title;
                    win.textview.text = contents;
                    win.textview.update_html_view ();
                    win.stack.set_visible_child (win.note_view);
                    win.format_button.sensitive = true;
                }
            });
        }
    }
}