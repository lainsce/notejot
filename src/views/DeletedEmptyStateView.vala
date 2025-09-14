namespace Notejot {
    public class DeletedEmptyStateView : Gtk.Box {

        private Gtk.Label header_label;

        public DeletedEmptyStateView () {
            Object (
                    orientation: Gtk.Orientation.VERTICAL,
                    spacing: 0
            );

            this.set_hexpand (true);
            this.add_css_class ("main-content");

            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            this.append (appbar);

            this.header_label = new Gtk.Label (_("Recently Deleted")) { halign = Gtk.Align.START };
            this.header_label.add_css_class ("header");
            this.append (this.header_label);

            var deleted_content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10) {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                vexpand = true
            };
            deleted_content_box.add_css_class ("empty-state-view");

            var deleted_title = new Gtk.Label (_("No Deleted Entries"));
            deleted_title.add_css_class ("empty-state-title");
            deleted_content_box.append (deleted_title);

            var deleted_subtitle = new Gtk.Label (_("Deleted notes will appear here"));
            deleted_subtitle.add_css_class ("empty-state-subtitle");
            deleted_content_box.append (deleted_subtitle);

            this.append (deleted_content_box);
        }

        public void set_header_label (string text) {
            this.header_label.set_label (text);
        }
    }
}
