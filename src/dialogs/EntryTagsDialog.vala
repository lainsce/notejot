namespace Notejot {
    public class EntryTagsDialog : He.Window {
        public signal void response (int response_id);

        private DataManager data_manager;
        private Gtk.FlowBox tags_flowbox;
        private GLib.List<Gtk.CheckButton> tag_check_buttons = new GLib.List<Gtk.CheckButton> ();
        private GLib.List<string> tag_uuids = new GLib.List<string> ();

        public EntryTagsDialog (Gtk.Window parent, DataManager data_manager, GLib.List<string> initially_selected) {
            Object (
                   parent : parent,
                   modal: true,
                   default_width: 440,
                   resizable: false
            );

            this.data_manager = data_manager;
            this.add_css_class ("dialog-content");

            // Header
            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            header_box.set_margin_top (12);
            header_box.set_margin_start (12);
            header_box.set_margin_end (12);
            header_box.set_margin_bottom (12);

            var title_label = new Gtk.Label (_("Select Tags"));
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

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolled.set_min_content_height (160);
            this.tags_flowbox = new Gtk.FlowBox () {
                selection_mode = Gtk.SelectionMode.NONE,
                valign = Gtk.Align.START,
                max_children_per_line = 3,
                min_children_per_line = 1,
                margin_top = 4, margin_bottom = 4, margin_start = 4, margin_end = 4
            };
            scrolled.set_child (this.tags_flowbox);
            main_box.append (scrolled);

            // Populate tags
            foreach (var tag in this.data_manager.get_tags ()) {
                var check = new Gtk.CheckButton.with_label (tag.name);
                bool preselected = false;
                for (int i = 0; i < initially_selected.length (); i++) {
                    if (initially_selected.nth_data (i) == tag.uuid) {
                        preselected = true;
                        break;
                    }
                }
                check.set_active (preselected);
                this.tag_check_buttons.append (check);
                this.tag_uuids.append (tag.uuid);
                this.tags_flowbox.insert (check, -1);
            }

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

        public GLib.List<string> get_selected_tag_uuids () {
            var selected = new GLib.List<string> ();
            for (int i = 0; i < this.tag_check_buttons.length (); i++) {
                if (this.tag_check_buttons.nth_data (i).get_active ()) {
                    selected.append (this.tag_uuids.nth_data (i));
                }
            }
            return selected;
        }
    }
}
