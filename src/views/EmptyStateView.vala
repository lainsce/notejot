namespace Notejot {
    public class EmptyStateView : Gtk.Box {

        public signal void add_entry_clicked ();

        private Gtk.Label header_label;

        public EmptyStateView () {
            Object (
                    orientation: Gtk.Orientation.VERTICAL,
                    spacing: 0
            );

            this.set_hexpand (true);
            this.add_css_class ("main-content");

            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            this.append (appbar);

            this.header_label = new Gtk.Label (_("No Entries")) { halign = Gtk.Align.START };
            this.header_label.add_css_class ("header");
            this.append (this.header_label);

            var empty_content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10) {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                vexpand = true
            };
            empty_content_box.add_css_class ("empty-state-view");

            var empty_title = new Gtk.Label (_("No Entries"));
            empty_title.add_css_class ("empty-state-title");
            empty_content_box.append (empty_title);

            var empty_subtitle = new Gtk.Label (_("Get started by adding your first entry"));
            empty_subtitle.add_css_class ("empty-state-subtitle");
            empty_content_box.append (empty_subtitle);

            var add_first_entry_button = new He.Button ("list-add-symbolic", _("Add First Entry"));
            add_first_entry_button.is_pill = true;
            add_first_entry_button.set_halign (Gtk.Align.CENTER);
            add_first_entry_button.clicked.connect (() => {
                add_entry_clicked ();
            });
            empty_content_box.append (add_first_entry_button);

            this.append (empty_content_box);
        }

        public void set_header_label (string text) {
            this.header_label.set_label (text);
        }
    }
}
