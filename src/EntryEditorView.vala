namespace Notejot {
    public class EntryEditorView : Gtk.Box {
        public He.TextField title_entry { get; private set; }
        public Gtk.TextView content_view { get; private set; }
        public He.TextField location_entry { get; private set; }

        public GLib.List<string> image_paths;

        public signal void saved (Entry? existing_entry, bool is_new);
        public signal void cancelled ();

        private DataManager data_manager;

        private Gtk.Revealer tags_revealer;
        private Gtk.Revealer images_revealer;
        private Gtk.Revealer location_revealer;

        private Gtk.FlowBox tags_flowbox;
        private GLib.List<Gtk.CheckButton> tag_check_buttons = new GLib.List<Gtk.CheckButton> ();
        private GLib.List<string> tag_uuids = new GLib.List<string> ();

        private Gtk.FlowBox image_preview_box;
        private He.Button add_image_button;
        private Gtk.ScrolledWindow side_scroller;
        private Gtk.Revealer side_pane_revealer;

        private He.Button save_button;
        private He.Button cancel_button;

        private Entry? editing_entry = null;
        private bool is_new = true;

        private bool dirty = false;

        public EntryEditorView (DataManager data_manager) {
            Object (orientation : Gtk.Orientation.VERTICAL, spacing : 0);
            this.data_manager = data_manager;
            this.add_css_class ("entry-editor");
            this.image_paths = new GLib.List<string> ();

            build_ui ();
            populate_tags ();
            reset_dirty ();
        }

        public void load_entry (Entry? entry) {
            this.editing_entry = entry;
            this.is_new = (entry == null);
            this.image_paths = new GLib.List<string> ();
            clear_image_previews ();
            reset_tag_checks ();

            bool has_tags = false;
            bool has_images = false;
            bool has_location = false;

            if (entry == null) {
                title_entry.get_internal_entry ().text = "";
                content_view.get_buffer ().text = "";
                location_entry.get_internal_entry ().text = "";
                add_image_button.set_sensitive (true);
            } else {
                title_entry.get_internal_entry ().text = entry.title;
                content_view.get_buffer ().text = entry.content;
                location_entry.get_internal_entry ().text = entry.location_address == null ? "" : entry.location_address;

                foreach (var tag_uuid in entry.tag_uuids) {
                    for (int i = 0; i < tag_uuids.length (); i++) {
                        if (tag_uuids.nth_data (i) == tag_uuid) {
                            tag_check_buttons.nth_data (i).set_active (true);
                            has_tags = true;
                        }
                    }
                }

                for (int i = 0; i < entry.image_paths.length (); i++) {
                    if (i >= 4)break;
                    var path = entry.image_paths.nth_data (i);
                    image_paths.append (path);
                    add_image_preview (path);
                    has_images = true;
                }
                add_image_button.set_sensitive (image_paths.length () < 4);

                if (location_entry.get_internal_entry ().text.strip () != "") {
                    has_location = true;
                }
            }

            tags_revealer.set_reveal_child (has_tags);
            images_revealer.set_reveal_child (has_images);
            location_revealer.set_reveal_child (has_location);
            update_side_pane_visibility ();

            reset_dirty ();
        }

        public void preselect_tag (string tag_uuid) {
            for (int i = 0; i < tag_uuids.length (); i++) {
                if (tag_uuids.nth_data (i) == tag_uuid) {
                    tag_check_buttons.nth_data (i).set_active (true);
                }
            }
            if (any_tag_selected ()) {
                tags_revealer.set_reveal_child (true);
            }
            update_side_pane_visibility ();
            mark_dirty ();
        }

        public GLib.List<string> get_selected_tag_uuids () {
            var selected = new GLib.List<string> ();
            for (int i = 0; i < tag_check_buttons.length (); i++) {
                if (tag_check_buttons.nth_data (i).get_active ()) {
                    selected.append (tag_uuids.nth_data (i));
                }
            }
            return selected;
        }

        public void refresh_tags () {
            var previously_selected = get_selected_tag_uuids ();
            populate_tags ();
            foreach (var uuid in previously_selected) {
                preselect_tag (uuid);
            }
            update_save_button_state ();
        }

        private void build_ui () {
            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            this.append (appbar);

            var header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            header.set_margin_start (18);
            header.set_margin_end (18);
            header.set_margin_bottom (6);
            this.append (header);

            title_entry = new He.TextField () { placeholder_text = _("Entry Title"), hexpand = true, is_outline = true };
            header.append (title_entry);

            var tags_btn = new He.Button ("tag-symbolic", "");
            tags_btn.is_disclosure = true;
            tags_btn.tooltip_text = _("Show / Hide Tags");
            tags_btn.valign = Gtk.Align.CENTER;
            tags_btn.clicked.connect (() => toggle_revealer (tags_revealer));
            header.append (tags_btn);

            var images_btn = new He.Button ("image-x-generic-symbolic", "");
            images_btn.is_disclosure = true;
            images_btn.tooltip_text = _("Show / Hide Images");
            images_btn.valign = Gtk.Align.CENTER;
            images_btn.clicked.connect (() => toggle_revealer (images_revealer));
            header.append (images_btn);

            var loc_btn = new He.Button ("mark-location-symbolic", "");
            loc_btn.is_disclosure = true;
            loc_btn.tooltip_text = _("Show / Hide Location");
            loc_btn.valign = Gtk.Align.CENTER;
            loc_btn.clicked.connect (() => toggle_revealer (location_revealer));
            header.append (loc_btn);

            var body_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            body_box.set_margin_start (18);
            body_box.set_margin_end (18);
            body_box.set_margin_bottom (6);
            body_box.set_vexpand (true);
            this.append (body_box);

            content_view = new Gtk.TextView () {
                wrap_mode = Gtk.WrapMode.WORD_CHAR,
                left_margin = 8, right_margin = 8,
                top_margin = 8, bottom_margin = 8,
                vexpand = true,
                hexpand = true
            };
            content_view.set_size_request (400, -1);
            content_view.add_css_class ("text-view");

            var editor_scroller = new Gtk.ScrolledWindow () { vexpand = true, hexpand = true };
            editor_scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            editor_scroller.set_child (content_view);
            body_box.append (editor_scroller);

            // Right side: side panel with revealers
            side_scroller = new Gtk.ScrolledWindow () { vexpand = true };
            side_scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            var side_panel = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            side_panel.set_size_request (280, -1);
            side_panel.set_valign (Gtk.Align.START);
            side_scroller.set_child (side_panel);
            side_pane_revealer = new Gtk.Revealer () { reveal_child = false };
            side_pane_revealer.set_child (side_scroller);
            body_box.append (side_pane_revealer);

            tags_revealer = new Gtk.Revealer () { reveal_child = false };
            var tags_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            tags_box.add_css_class ("card");
            var tags_title = new Gtk.Label (_("Tags")) { halign = Gtk.Align.START };
            tags_title.add_css_class ("section-title");
            tags_box.append (tags_title);

            var tags_scrolled = new Gtk.ScrolledWindow ();
            tags_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            tags_scrolled.set_min_content_height (80);
            tags_flowbox = new Gtk.FlowBox () {
                selection_mode = Gtk.SelectionMode.NONE,
                valign = Gtk.Align.START,
                max_children_per_line = 6,
                margin_top = 8, margin_bottom = 8, margin_start = 8, margin_end = 8
            };
            tags_scrolled.set_child (tags_flowbox);
            tags_box.append (tags_scrolled);
            tags_revealer.set_child (tags_box);
            side_panel.append (tags_revealer);

            images_revealer = new Gtk.Revealer () { reveal_child = false };
            var images_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            images_box.add_css_class ("card");
            var images_title = new Gtk.Label (_("Images (Max 4)")) { halign = Gtk.Align.START };
            images_title.add_css_class ("section-title");
            images_box.append (images_title);

            var img_toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            add_image_button = new He.Button ("", _("Add Images"));
            add_image_button.margin_start = 8;
            add_image_button.is_fill = true;
            add_image_button.clicked.connect (on_add_images_clicked);
            img_toolbar.append (add_image_button);
            images_box.append (img_toolbar);

            image_preview_box = new Gtk.FlowBox () {
                min_children_per_line = 4, max_children_per_line = 4,
                margin_top = 8, margin_bottom = 8, margin_start = 8, margin_end = 8
            };
            images_box.append (image_preview_box);
            images_revealer.set_child (images_box);
            side_panel.append (images_revealer);

            location_revealer = new Gtk.Revealer () { reveal_child = false };
            var location_card = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            location_card.add_css_class ("card");
            var location_title = new Gtk.Label (_("Location")) { halign = Gtk.Align.START };
            location_title.add_css_class ("section-title");
            location_card.append (location_title);
            location_entry = new He.TextField () {
                support_text = _("City, State, Country"), hexpand = true,
                margin_top = 8, margin_bottom = 8, margin_start = 8, margin_end = 8
            };
            location_card.append (location_entry);
            location_revealer.set_child (location_card);
            side_panel.append (location_revealer);

            var actions_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            actions_bar.set_margin_start (18);
            actions_bar.set_margin_end (18);
            actions_bar.set_margin_bottom (18);
            actions_bar.set_margin_top (12);
            actions_bar.set_halign (Gtk.Align.END);
            cancel_button = new He.Button ("", _("Cancel"));
            cancel_button.is_tint = true;
            cancel_button.clicked.connect (() => {
                cancelled ();
            });
            actions_bar.append (cancel_button);

            save_button = new He.Button ("", _("Save"));
            save_button.is_fill = true;
            save_button.clicked.connect (on_save_clicked);
            actions_bar.append (save_button);

            this.append (actions_bar);

            var title_entry_internal = title_entry.get_internal_entry ();
            if (title_entry_internal != null) {
                title_entry_internal.changed.connect (() => {
                    mark_dirty ();
                });
            }
            content_view.get_buffer ().changed.connect (() => mark_dirty ());
            var loc_entry_internal = location_entry.get_internal_entry ();
            if (loc_entry_internal != null) {
                loc_entry_internal.changed.connect (() => {
                    mark_dirty ();
                    if (loc_entry_internal.text.strip () != "") {
                        location_revealer.set_reveal_child (true);
                    } else {
                        location_revealer.set_reveal_child (false);
                    }
                    update_side_pane_visibility ();
                });
            }

            update_side_pane_visibility ();
        }

        private void populate_tags () {
            while (tags_flowbox.get_first_child () != null) {
                tags_flowbox.remove (tags_flowbox.get_first_child ());
            }
            tag_check_buttons = new GLib.List<Gtk.CheckButton> ();
            tag_uuids = new GLib.List<string> ();

            foreach (var tag in data_manager.get_tags ()) {
                var check = new Gtk.CheckButton.with_label (tag.name);
                check.toggled.connect (() => {
                    mark_dirty ();
                    if (any_tag_selected ()) {
                        tags_revealer.set_reveal_child (true);
                    } else {
                        tags_revealer.set_reveal_child (false);
                    }
                    update_side_pane_visibility ();
                });
                tag_check_buttons.append (check);
                tag_uuids.append (tag.uuid);
                tags_flowbox.insert (check, -1);
            }
        }

        private bool any_tag_selected () {
            for (int i = 0; i < tag_check_buttons.length (); i++) {
                if (tag_check_buttons.nth_data (i).get_active ())return true;
            }
            return false;
        }

        private void reset_tag_checks () {
            for (int i = 0; i < tag_check_buttons.length (); i++) {
                tag_check_buttons.nth_data (i).set_active (false);
            }
        }

        private void clear_image_previews () {
            while (image_preview_box.get_first_child () != null) {
                image_preview_box.remove (image_preview_box.get_first_child ());
            }
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
                image_paths.remove (path);
                image_preview_box.remove (overlay);
                add_image_button.set_sensitive (image_paths.length () < 4);
                if (image_paths.length () == 0) {
                    images_revealer.set_reveal_child (false);
                }
                update_side_pane_visibility ();
                mark_dirty ();
            });
            overlay.add_overlay (remove_btn);

            image_preview_box.insert (overlay, -1);
            images_revealer.set_reveal_child (true);
            update_side_pane_visibility ();
            mark_dirty ();
        }

        private void mark_dirty () {
            if (!dirty) {
                dirty = true;
                update_save_button_state ();
            } else {
                update_save_button_state ();
            }
        }

        private void reset_dirty () {
            dirty = false;
            update_save_button_state ();
        }

        private void update_save_button_state () {
            bool has_text = false;
            var t = title_entry.get_internal_entry ().text;
            if (t != null && t.strip () != "") {
                has_text = true;
            } else {
                Gtk.TextIter s, e;
                content_view.get_buffer ().get_bounds (out s, out e);
                var c = content_view.get_buffer ().get_text (s, e, false);
                has_text = c.strip () != "";
            }
            save_button.set_sensitive (dirty && has_text);
        }

        public bool is_dirty () {
            return dirty;
        }

        public void clear_dirty () {
            reset_dirty ();
        }

        private void toggle_revealer (Gtk.Revealer r) {
            r.set_reveal_child (!r.get_reveal_child ());
            r.set_visible (r.get_reveal_child ());
            update_side_pane_visibility ();
        }

        private void update_side_pane_visibility () {
            if (side_pane_revealer == null)return;
            bool any_visible = tags_revealer.get_reveal_child () || images_revealer.get_reveal_child () || location_revealer.get_reveal_child ();

            if (any_visible) {
                side_pane_revealer.set_visible (true);
                side_pane_revealer.set_reveal_child (true);
            } else {
                // Start hide animation
                side_pane_revealer.set_reveal_child (false);
                bool still_none = !tags_revealer.get_reveal_child () && !images_revealer.get_reveal_child () && !location_revealer.get_reveal_child ();
                if (still_none) {
                    side_pane_revealer.set_visible (false);
                }
            }
        }

        private string get_content () {
            Gtk.TextIter start, end;
            content_view.get_buffer ().get_bounds (out start, out end);
            return content_view.get_buffer ().get_text (start, end, false);
        }

        private void on_save_clicked () {
            var title = title_entry.get_internal_entry ().text;
            var content = get_content ();
            if (title == "" && content == "") {
                cancelled ();
                return;
            }
            if (editing_entry == null) {
                saved (null, true);
            } else {
                saved (editing_entry, false);
            }
            reset_dirty ();
        }

        private void on_add_images_clicked () {
            if (image_paths.length () >= 4)return;
            images_revealer.set_reveal_child (true);
            update_side_pane_visibility ();

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
                        if (image_paths.length () >= 4)break;
                        var f = files.get_item (i) as File;
                        var p = f.get_path ();
                        image_paths.append (p);
                        add_image_preview (p);
                    }
                    if (image_paths.length () >= 4) {
                        add_image_button.set_sensitive (false);
                    }
                } catch (Error e) {
                }
            });
        }
    }
}
