namespace Notejot {
    public class EntryLocationDialog : He.Window {
        public signal void response (int response_id);
        public He.TextField location_entry { get; private set; }

        public EntryLocationDialog (Gtk.Window parent, string initial_text) {
            Object (
                   parent : parent,
                   modal: true,
                   default_width: 440,
                   resizable: false
            );

            this.add_css_class ("dialog-content");

            // Header
            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            header_box.set_margin_top (12);
            header_box.set_margin_start (12);
            header_box.set_margin_end (12);
            header_box.set_margin_bottom (12);

            var title_label = new Gtk.Label (_("Set Location"));
            title_label.add_css_class ("title-3");
            header_box.append (title_label);
            header_box.append (new Gtk.Label ("") { hexpand = true });

            var close_button = new He.Button ("window-close-symbolic", "");
            close_button.tooltip_text = _("Close");
            close_button.is_disclosure = true;
            close_button.clicked.connect (() => {
                response (Gtk.ResponseType.CANCEL);
                this.close ();
            });
            header_box.append (close_button);

            var winhandle = new Gtk.WindowHandle ();
            winhandle.set_child (header_box);

            // Main content
            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            main_box.set_margin_top (6);
            main_box.set_margin_bottom (12);
            main_box.set_margin_start (12);
            main_box.set_margin_end (12);

            this.location_entry = new He.TextField () { support_text = _("City, State, Country"), hexpand = true, is_outline = true };
            var internal = this.location_entry.get_internal_entry ();
            if (internal != null) internal.text = initial_text;
            main_box.append (this.location_entry);

            // Bottom buttons
            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            button_box.set_halign (Gtk.Align.END);
            button_box.set_margin_top (12);
            button_box.set_margin_bottom (12);
            button_box.set_margin_start (12);
            button_box.set_margin_end (12);

            var cancel_btn = new He.Button ("", _("Cancel"));
            cancel_btn.is_tint = true;
            cancel_btn.clicked.connect (() => {
                response (Gtk.ResponseType.CANCEL);
                this.close ();
            });
            button_box.append (cancel_btn);

            var save_btn = new He.Button ("", _("Save"));
            save_btn.is_fill = true;
            save_btn.clicked.connect (() => {
                response (Gtk.ResponseType.ACCEPT);
                this.close ();
            });
            button_box.append (save_btn);

            var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            container.append (winhandle);
            container.append (main_box);
            container.append (button_box);
            this.set_child (container);
        }

        public string get_location_text () {
            return this.location_entry.get_internal_entry ().text;
        }
    }
}
