namespace Notejot {
    public class EntryImagesDialog : He.Window {
        public signal void response (int response_id);

        private GLib.List<string> image_paths;
        private Gtk.FlowBox image_preview_box;
        private He.Button add_image_button;

        public EntryImagesDialog (Gtk.Window parent, GLib.List<string> initial_paths) {
            Object (
                   parent : parent,
                   modal: true,
                   default_width: 520,
                   resizable: false
            );

            this.add_css_class ("dialog-content");
            this.image_paths = new GLib.List<string> ();
            foreach (var p in initial_paths) { this.image_paths.append (p); }

            // Header
            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            header_box.set_margin_top (12);
            header_box.set_margin_start (12);
            header_box.set_margin_end (12);
            header_box.set_margin_bottom (12);

            var title_label = new Gtk.Label (_("Manage Images"));
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

            // Toolbar with Add button
            var img_toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            this.add_image_button = new He.Button ("", _("Add Images"));
            this.add_image_button.is_fill = true;
            this.add_image_button.clicked.connect (on_add_images_clicked);
            img_toolbar.append (this.add_image_button);
            main_box.append (img_toolbar);

            // Previews
            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            this.image_preview_box = new Gtk.FlowBox () {
                min_children_per_line = 4,
                max_children_per_line = 4,
                margin_top = 8, margin_bottom = 8, margin_start = 8, margin_end = 8
            };
            scrolled.set_child (this.image_preview_box);
            main_box.append (scrolled);

            // Populate previews
            foreach (var p in this.image_paths) {
                add_image_preview (p);
            }
            this.add_image_button.set_sensitive (this.image_paths.length () < 4);

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

        private void add_image_preview (string path) {
            var overlay = new Gtk.Overlay ();
            overlay.set_size_request (72, 72);
            var picture = new Gtk.Picture.for_filename (path);
            picture.set_halign (Gtk.Align.CENTER);
            picture.set_can_shrink (true);
            overlay.set_child (picture);

            var remove_btn = new He.Button ("window-close-symbolic", "");
            remove_btn.is_disclosure = true;
            remove_btn.set_halign (Gtk.Align.END);
            remove_btn.set_valign (Gtk.Align.START);
            remove_btn.clicked.connect (() => {
                this.image_paths.remove (path);
                this.image_preview_box.remove (overlay);
                this.add_image_button.set_sensitive (this.image_paths.length () < 4);
            });
            overlay.add_overlay (remove_btn);

            this.image_preview_box.insert (overlay, -1);
        }

        private void on_add_images_clicked () {
            if (this.image_paths.length () >= 4)return;

            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_title (_("Select Images"));
            file_dialog.set_accept_label (_("Open"));

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Image Files"));
            filter.add_pixbuf_formats ();
            var list_store = new GLib.ListStore (typeof (Gtk.FileFilter));
            list_store.append (filter);
            file_dialog.set_filters (list_store);

            file_dialog.open_multiple.begin ((Gtk.Window) this.get_root (), null, (obj, res) => {
                try {
                    var files = file_dialog.open_multiple.end (res);
                    for (int i = 0; i < files.get_n_items (); i++) {
                        if (this.image_paths.length () >= 4)break;
                        var f = files.get_item (i) as File;
                        var p = f.get_path ();
                        this.image_paths.append (p);
                        add_image_preview (p);
                    }
                    if (this.image_paths.length () >= 4) {
                        this.add_image_button.set_sensitive (false);
                    }
                } catch (Error e) {
                }
            });
        }

        public GLib.List<string> get_image_paths () {
            var out_list = new GLib.List<string> ();
            foreach (var p in this.image_paths) out_list.append (p);
            return out_list;
        }
    }
}
