namespace Notejot {
    public class EntryEditorView : Gtk.Box {
        public He.TextField title_entry { get; private set; }
        public Gtk.TextView content_view { get; private set; }
        public He.TextField location_entry { get; private set; }

        public GLib.List<string> image_paths;

        public signal void saved (Entry? existing_entry, bool is_new);
        public signal void cancelled ();

        private DataManager data_manager;
        // Dialog-based selections
        private GLib.List<string> selected_tag_uuids = new GLib.List<string> ();

        private He.Button save_button;
        private He.Button cancel_button;

        private Entry? editing_entry = null;
        private bool is_new = true;

        private bool dirty = false;

        // Indicator lines
        private Gtk.Box indicators_box;
        private Gtk.Label tags_indicator;
        private Gtk.Label location_indicator;
        private Gtk.Label images_indicator;

        public EntryEditorView (DataManager data_manager) {
            Object (orientation : Gtk.Orientation.VERTICAL, spacing : 0);
            this.data_manager = data_manager;
            this.add_css_class ("entry-editor");
            this.image_paths = new GLib.List<string> ();

            build_ui ();
            reset_dirty ();
        }

        public void load_entry (Entry? entry) {
            this.editing_entry = entry;
            this.is_new = (entry == null);
            this.image_paths = new GLib.List<string> ();
            this.selected_tag_uuids = new GLib.List<string> ();

            if (entry == null) {
                title_entry.get_internal_entry ().text = "";
                content_view.get_buffer ().text = "";
                location_entry.get_internal_entry ().text = "";
            } else {
                title_entry.get_internal_entry ().text = entry.title;
                content_view.get_buffer ().text = entry.content;
                location_entry.get_internal_entry ().text = entry.location_address == null ? "" : entry.location_address;
                for (int i = 0; i < entry.tag_uuids.length (); i++) {
                    var uuid = entry.tag_uuids.nth_data (i);
                    if (uuid != null && uuid != "") {
                        this.selected_tag_uuids.append (uuid);
                    }
                }
                for (int i = 0; i < entry.image_paths.length (); i++) {
                    if (i >= 4) break;
                    var path = entry.image_paths.nth_data (i);
                    if (path != null && path != "") {
                        this.image_paths.append (path);
                    }
                }
            }
            reset_dirty ();
            update_indicators ();
        }

        public void preselect_tag (string tag_uuid) {
            bool exists = false;
            for (int i = 0; i < selected_tag_uuids.length (); i++) {
                if (selected_tag_uuids.nth_data (i) == tag_uuid) { exists = true; break; }
            }
            if (!exists) {
                selected_tag_uuids.append (tag_uuid);
                mark_dirty ();
            }
        }

        public GLib.List<string> get_selected_tag_uuids () {
            var out_list = new GLib.List<string> ();
            for (int i = 0; i < selected_tag_uuids.length (); i++) {
                out_list.append (selected_tag_uuids.nth_data (i));
            }
            return out_list;
        }

        public void refresh_tags () {
            // Ensure selected tags still exist
            var existing = new GLib.HashTable<string, bool> (GLib.str_hash, GLib.str_equal);
            foreach (var tag in data_manager.get_tags ()) {
                existing.insert (tag.uuid, true);
            }
            var filtered = new GLib.List<string> ();
            for (int i = 0; i < selected_tag_uuids.length (); i++) {
                var u = selected_tag_uuids.nth_data (i);
                if (existing.contains (u)) filtered.append (u);
            }
            selected_tag_uuids = (owned) filtered;
            update_save_button_state ();
        }

        private void build_ui () {
            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            appbar.is_compact = true;
            this.append (appbar);

            var toolbar = new Gtk.CenterBox ();
            toolbar.set_margin_start (18);
            toolbar.set_margin_end (18);
            toolbar.set_margin_bottom (12);
            this.append (toolbar);

            // Hidden location storage (dialog-driven)
            location_entry = new He.TextField ();

            // Top-left: Back (Cancel) button
            cancel_button = new He.Button ("go-previous-symbolic", "");
            cancel_button.is_disclosure = true;
            cancel_button.tooltip_text = _("Back");
            cancel_button.valign = Gtk.Align.CENTER;
            cancel_button.clicked.connect (() => {
                cancelled ();
            });
            toolbar.set_start_widget (cancel_button);

            // Top-center: header controls (Tags / Images / Location)
            var center_controls = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            center_controls.set_halign (Gtk.Align.CENTER);

            var tags_btn = new He.Button ("tag-symbolic", "");
            tags_btn.is_disclosure = true;
            tags_btn.tooltip_text = _("Edit Tags");
            tags_btn.valign = Gtk.Align.CENTER;
            tags_btn.clicked.connect (() => {
                var dlg = new EntryTagsDialog ((Gtk.Window) this.get_root (), this.data_manager, get_selected_tag_uuids ());
                dlg.present ();
                dlg.response.connect ((response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        var _tmp_tags = dlg.get_selected_tag_uuids ();
                        var rebuilt = new GLib.List<string> ();
                        for (int i = 0; i < _tmp_tags.length (); i++) {
                            rebuilt.append (_tmp_tags.nth_data (i));
                        }
                        this.selected_tag_uuids = (owned) rebuilt;
                        mark_dirty ();
                        update_indicators ();
                    }
                    dlg.destroy ();
                });
            });
            center_controls.append (tags_btn);

            var images_btn = new He.Button ("image-x-generic-symbolic", "");
            images_btn.is_disclosure = true;
            images_btn.tooltip_text = _("Manage Images");
            images_btn.valign = Gtk.Align.CENTER;
            images_btn.clicked.connect (() => {
                var dlg = new EntryImagesDialog ((Gtk.Window) this.get_root (), this.image_paths);
                dlg.present ();
                dlg.response.connect ((response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        var _tmp_imgs = dlg.get_image_paths ();
                        var rebuilt_i = new GLib.List<string> ();
                        for (int i = 0; i < _tmp_imgs.length (); i++) {
                            rebuilt_i.append (_tmp_imgs.nth_data (i));
                        }
                        this.image_paths = (owned) rebuilt_i;
                        mark_dirty ();
                        update_indicators ();
                    }
                    dlg.destroy ();
                });
            });
            center_controls.append (images_btn);

            var loc_btn = new He.Button ("mark-location-symbolic", "");
            loc_btn.is_disclosure = true;
            loc_btn.tooltip_text = _("Set Location");
            loc_btn.valign = Gtk.Align.CENTER;
            loc_btn.clicked.connect (() => {
                var current_text = "";
                var internal = this.location_entry.get_internal_entry ();
                if (internal != null) current_text = internal.text;
                var dlg = new EntryLocationDialog ((Gtk.Window) this.get_root (), current_text);
                dlg.present ();
                dlg.response.connect ((response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        var ie = this.location_entry.get_internal_entry ();
                        if (ie != null) ie.text = dlg.get_location_text ();
                        mark_dirty ();
                        update_indicators ();
                    }
                    dlg.destroy ();
                });
            });
            center_controls.append (loc_btn);
            toolbar.set_center_widget (center_controls);

            // Top-right: Save button
            save_button = new He.Button ("", _("Save"));
            save_button.is_fill = true;
            save_button.clicked.connect (on_save_clicked);
            toolbar.set_end_widget (save_button);

            var body_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            body_box.set_margin_start (18);
            body_box.set_margin_end (18);
            body_box.set_margin_bottom (18);
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
            // Main editor column: Indicators + Title + Content
            var editor_column = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            editor_column.set_vexpand (true);
            editor_column.set_hexpand (true);
            
            // Indicator lines
            indicators_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            indicators_box.set_margin_bottom (8);
            indicators_box.add_css_class ("entry-indicators");
            
            tags_indicator = new Gtk.Label ("") { halign = Gtk.Align.START };
            tags_indicator.add_css_class ("indicator-label");
            indicators_box.append (tags_indicator);
            
            location_indicator = new Gtk.Label ("") { halign = Gtk.Align.START };
            location_indicator.add_css_class ("indicator-label");
            indicators_box.append (location_indicator);
            
            images_indicator = new Gtk.Label ("") { halign = Gtk.Align.START };
            images_indicator.add_css_class ("indicator-label");
            indicators_box.append (images_indicator);
            
            editor_column.append (indicators_box);
            
            title_entry = new He.TextField () { placeholder_text = _("Entry Title"), hexpand = true, is_outline = true };
            editor_column.append (title_entry);
            editor_column.append (editor_scroller);
            body_box.append (editor_column);

            // Actions are now in the top toolbar (Back on the left, Save on the right)

            var title_entry_internal = title_entry.get_internal_entry ();
            if (title_entry_internal != null) {
                title_entry_internal.changed.connect (() => {
                    mark_dirty ();
                });
            }
            content_view.get_buffer ().changed.connect (() => mark_dirty ());
            // Location is edited via dialog; no inline change handler needed
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

        private void update_indicators () {
            // Update tags indicator
            if (selected_tag_uuids.length () > 0) {
                var tag_names = new GLib.List<string> ();
                foreach (var tag in data_manager.get_tags ()) {
                    for (int i = 0; i < selected_tag_uuids.length (); i++) {
                        if (selected_tag_uuids.nth_data (i) == tag.uuid) {
                            tag_names.append (tag.name);
                            break;
                        }
                    }
                }
                if (tag_names.length () > 0) {
                    var names_str = "";
                    for (int i = 0; i < tag_names.length (); i++) {
                        if (i > 0) names_str += ", ";
                        names_str += tag_names.nth_data (i);
                    }
                    tags_indicator.set_text (@"🏷️ $names_str");
                    tags_indicator.set_visible (true);
                } else {
                    tags_indicator.set_visible (false);
                }
            } else {
                tags_indicator.set_visible (false);
            }

            // Update location indicator
            var location_text = location_entry.get_internal_entry ().text;
            if (location_text != null && location_text.strip () != "") {
                location_indicator.set_text (@"📍 $location_text");
                location_indicator.set_visible (true);
            } else {
                location_indicator.set_visible (false);
            }

            // Update images indicator
            if (image_paths.length () > 0) {
                images_indicator.set_text (@"🖼️ $(image_paths.length ()) image(s)");
                images_indicator.set_visible (true);
            } else {
                images_indicator.set_visible (false);
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
                // Reset dirty BEFORE emitting the saved signal so navigation checks see a clean state
                reset_dirty ();
                saved (null, true);
            } else {
                reset_dirty ();
                saved (editing_entry, false);
            }
        }

        // Images are managed via dialog now
    }
}
