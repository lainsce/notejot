namespace Notejot {
    public class Sidebar : Gtk.Box {
        public signal void view_switched (string view_name);
        public signal void tag_selected (string? tag_uuid, string display_name);
        public signal void add_tag_clicked ();
        public signal void settings_clicked ();
        public signal void edit_tag_requested (string uuid);

        private DataManager data_manager;
        private SettingsManager settings_manager;

        private bool editing_mode = false;

        private Gtk.ListBox tag_list_box;
        private Gtk.Button insights_button;
        private Gtk.Button places_button;
        private Gtk.Box tags_header_box;
        private He.Button add_tag_button;
        private He.Button edit_button;
        private Gtk.CheckButton insights_switch;
        private Gtk.CheckButton places_switch;
        private Gtk.Overlay insights_card_overlay;
        private Gtk.Overlay places_card_overlay;

        // Insights (sidebar card) stats
        private Gtk.Label insights_year_number_label; // Entries This Year
        private Gtk.Label insights_days_number_label; // Days Journaled
        private Gtk.Label insights_words_number_label; // Total Words

        private Gtk.Label places_subtitle_number;

        public Sidebar (DataManager data_manager) {
            Object (
                    orientation: Gtk.Orientation.VERTICAL,
                    spacing: 0
            );
            this.data_manager = data_manager;
            this.settings_manager = SettingsManager.get_default ();

            this.set_size_request (325, -1);
            this.set_hexpand_set (false);
            this.set_hexpand (false);
            this.add_css_class ("sidebar");

            var appbar = new He.AppBar ();
            appbar.show_right_title_buttons = false;
            appbar.set_size_request (325, -1);
            this.append (appbar);

            var header_buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            header_buttons_box.set_halign (Gtk.Align.END);
            header_buttons_box.set_margin_end (12);
            header_buttons_box.set_margin_top (4);
            header_buttons_box.set_margin_bottom (12);
            this.append (header_buttons_box);

            this.edit_button = new He.Button ("document-edit-symbolic", "");
            edit_button.tooltip_text = _("Edit Sidebar");
            edit_button.is_disclosure = true;
            edit_button.clicked.connect (this.toggle_editing_mode);
            header_buttons_box.append (edit_button);

            // Settings button in the sidebar AppBar
            var settings_button = new He.Button ("open-menu-symbolic", "");
            settings_button.tooltip_text = _("Open Settings…");
            settings_button.is_disclosure = true;
            settings_button.clicked.connect (() => {
                settings_clicked ();
            });
            header_buttons_box.append (settings_button);

            // Insights card with detailed contents
            this.insights_button = create_insights_card (out this.insights_year_number_label,
                                                         out this.insights_days_number_label,
                                                         out this.insights_words_number_label);
            insights_button.clicked.connect (() => {
                if (editing_mode)return;
                view_switched ("insights");
                tag_list_box.unselect_all ();
            });

            // Wrap Insights button in top-level overlay and move checkbutton outside the button
            this.insights_card_overlay = new Gtk.Overlay ();
            this.insights_card_overlay.set_child (this.insights_button);

            // Recreate insights checkbutton outside the button
            this.insights_switch = new Gtk.CheckButton () { halign = Gtk.Align.END, valign = Gtk.Align.START, visible = false, tooltip_text = _("Show Insights") };
            this.insights_switch.set_active (settings_manager.get_insights_card_enabled ());
            this.insights_switch.set_margin_top (6);
            this.insights_switch.set_margin_end (24);
            this.insights_switch.add_css_class ("selection-mode");
            this.insights_switch.toggled.connect (() => {
                settings_manager.set_insights_card_enabled (this.insights_switch.get_active ());
                if (!this.editing_mode) {
                    this.insights_card_overlay.set_visible (this.insights_switch.get_active ());
                } else {
                    this.insights_card_overlay.set_visible (true);
                }
            });
            this.insights_card_overlay.add_overlay (this.insights_switch);
            this.append (this.insights_card_overlay);

            // Places card (keeps existing simple counter)
            this.places_button = create_sidebar_card (
                                                      _("Places"),
                                                      _("0"),
                                                      "places-card",
                                                      out this.places_subtitle_number
            );
            places_button.set_size_request (-1, 148);
            places_button.clicked.connect (() => {
                if (editing_mode)return;
                view_switched ("places");
                tag_list_box.unselect_all ();
            });

            // Wrap Places button in top-level overlay and move checkbutton outside the button
            this.places_card_overlay = new Gtk.Overlay ();
            this.places_card_overlay.set_child (this.places_button);

            // Recreate places checkbutton outside the button
            this.places_switch = new Gtk.CheckButton () { halign = Gtk.Align.END, valign = Gtk.Align.START, visible = false, tooltip_text = _("Show Places") };
            this.places_switch.set_active (settings_manager.get_places_card_enabled ());
            this.places_switch.set_margin_top (10);
            this.places_switch.set_margin_end (24);
            this.places_switch.add_css_class ("selection-mode");
            this.places_switch.toggled.connect (() => {
                settings_manager.set_places_card_enabled (this.places_switch.get_active ());
                if (!this.editing_mode) {
                    this.places_card_overlay.set_visible (this.places_switch.get_active ());
                } else {
                    this.places_card_overlay.set_visible (true);
                }
            });
            this.places_card_overlay.add_overlay (this.places_switch);
            this.append (this.places_card_overlay);

            this.tags_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            tags_header_box.add_css_class ("tags-header");
            tags_header_box.set_size_request (325, -1);
            this.append (tags_header_box);
            var tags_label = new Gtk.Label (_("Tags")) { hexpand = true, halign = Gtk.Align.START };
            tags_label.add_css_class ("header");
            tags_header_box.append (tags_label);
            this.add_tag_button = new He.Button ("list-add-symbolic", "");
            add_tag_button.tooltip_text = _("Add Tag…");
            add_tag_button.is_disclosure = true;
            add_tag_button.clicked.connect (() => {
                add_tag_clicked ();
            });
            tags_header_box.append (add_tag_button);
            var scrolled_tags = new Gtk.ScrolledWindow () { vexpand = true };
            scrolled_tags.set_size_request (325, -1);
            scrolled_tags.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            this.append (scrolled_tags);
            this.tag_list_box = new Gtk.ListBox ();
            this.tag_list_box.add_css_class ("sidebar-list");
            this.tag_list_box.set_selection_mode (Gtk.SelectionMode.SINGLE);
            this.tag_list_box.row_selected.connect (on_tag_selected);
            scrolled_tags.set_child (this.tag_list_box);

            this.insights_card_overlay.set_visible (settings_manager.get_insights_card_enabled ());
            this.places_card_overlay.set_visible (settings_manager.get_places_card_enabled ());
        }

        private void on_tag_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            if (row is TagRow) {
                var tag_row = (TagRow) row;
                tag_selected (tag_row.tag_uuid, tag_row.display_name);
            }
        }

        public void refresh_tags () {
            while (this.tag_list_box.get_first_child () != null) {
                this.tag_list_box.remove (this.tag_list_box.get_first_child ());
            }

            // All Entries
            var all_entries_row = new TagRow (null, _("All Entries"), data_manager.get_entries (false).length ().to_string (), "user-home-symbolic", "all");
            this.tag_list_box.append (all_entries_row);

            // Bookmarks
            var pinned_entries = data_manager.get_pinned_entries ();
            if (pinned_entries.length () > 0) {
                var bookmarks_row = new TagRow (null, _("Bookmarks"), pinned_entries.length ().to_string (), "user-bookmarks-symbolic", "pinned");
                this.tag_list_box.append (bookmarks_row);
            }

            // User-created tags
            var sorted_tags = sort_tags (this.data_manager.get_tags (), settings_manager.get_tag_order ());

            foreach (var tag in sorted_tags) {
                var row = new TagRow (tag.color, tag.name, data_manager.get_entries_for_tag (tag.uuid).length ().to_string (), tag.icon_name, tag.uuid);
                row.deleted.connect ((uuid) => {
                    this.data_manager.delete_tag (uuid);
                    this.data_manager.save_data ();
                    this.refresh_tags ();
                });
                row.edit_requested.connect ((uuid) => {
                    edit_tag_requested (uuid);
                });
                this.tag_list_box.append (row);
                this.setup_tag_dnd (row);
            }

            // Recently Deleted
            var deleted_row = new TagRow (null, _("Recently Deleted"), data_manager.get_entries (true).length ().to_string (), "user-trash-symbolic", "deleted");
            this.tag_list_box.append (deleted_row);

            this.tag_list_box.select_row (this.tag_list_box.get_row_at_index (0));

            update_edit_mode_ui ();
        }

        public void update_stats () {
            int year_count = 0;
            var unique_days = new GLib.HashTable<string, bool> (GLib.str_hash, GLib.str_equal);
            int words_all_time = 0;

            var now = new GLib.DateTime.now_local ();
            foreach (var entry in this.data_manager.get_entries (false)) {
                if (entry.date.get_year () == now.get_year ()) {
                    year_count++;
                }
                var day_key = entry.date.format ("%Y-%m-%d");
                if (!unique_days.contains (day_key)) {
                    unique_days.insert (day_key, true);
                }
                var text = entry.content;
                if (text != "") {
                    var tokens = text.strip ().split_set (" \t\r\n", 0);
                    foreach (var tok in tokens) {
                        if (tok != "") {
                            words_all_time++;
                        }
                    }
                }
            }

            var unique_locations = this.data_manager.get_unique_locations ();
            int location_count = (int) unique_locations.length ();

            if (this.insights_year_number_label != null) {
                this.insights_year_number_label.set_label (@"$year_count");
            }
            if (this.insights_days_number_label != null) {
                this.insights_days_number_label.set_label (@"$(unique_days.size ())");
            }
            if (this.insights_words_number_label != null) {
                this.insights_words_number_label.set_label (@"$words_all_time");
            }
            this.places_subtitle_number.set_label (@"$location_count");
        }

        private Gtk.Button create_sidebar_card (string title, string subtitle, string style_class, out Gtk.Label number_label_out) {
            var button = new Gtk.Button ();
            button.add_css_class ("card");
            button.add_css_class (style_class);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) { halign = Gtk.Align.START, hexpand = true };
            button.set_child (box);

            var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.append (title_box);

            var title_label = new Gtk.Label (title) { hexpand = true };
            title_label.add_css_class ("title");
            title_label.set_xalign (0.0f);
            title_box.append (title_label);

            var subtitle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            box.append (subtitle_box);

            var image = new Gtk.Image.from_icon_name ("location-active-symbolic");
            image.pixel_size = 24;
            subtitle_box.append (image);

            string number = subtitle;
            number_label_out = new Gtk.Label (number);
            number_label_out.add_css_class ("stat-value");
            number_label_out.set_xalign (0.0f);
            subtitle_box.append (number_label_out);

            return button;
        }

        private Gtk.Button create_insights_card (out Gtk.Label year_number_out,
                                                 out Gtk.Label days_number_out,
                                                 out Gtk.Label words_number_out) {
            var button = new Gtk.Button ();
            button.add_css_class ("card");
            button.add_css_class ("insights-card");

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) { halign = Gtk.Align.START, hexpand = true };
            button.set_child (root);

            var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            root.append (title_box);

            var title_label = new Gtk.Label (_("Insights")) { hexpand = true };
            title_label.add_css_class ("title");
            title_label.set_xalign (0.0f);
            title_box.append (title_label);

            // Checkbutton is created and overlaid at the top-level overlay in the constructor

            var content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 42);
            root.append (content);

            var left_col = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) { halign = Gtk.Align.START };
            year_number_out = new Gtk.Label ("0");
            year_number_out.add_css_class ("stat-value");
            year_number_out.set_xalign (0.0f);
            left_col.append (year_number_out);

            var type_label = new Gtk.Label (_("Entries"));
            type_label.add_css_class ("stat-title");
            type_label.set_xalign (0.0f);
            type_label.set_wrap (true);
            type_label.set_max_width_chars (14);
            left_col.append (type_label);

            var year_label = new Gtk.Label (_("This Year"));
            year_label.add_css_class ("stat-title");
            year_label.set_xalign (0.0f);
            year_label.set_wrap (true);
            year_label.set_max_width_chars (14);
            left_col.append (year_label);

            content.append (left_col);

            var right_col = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) { halign = Gtk.Align.START };

            var r1 = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) { halign = Gtk.Align.START };
            var r1top = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var cal_icon = new Gtk.Image.from_icon_name ("x-office-calendar-symbolic");
            cal_icon.set_pixel_size (16);
            r1top.append (cal_icon);
            days_number_out = new Gtk.Label ("0");
            days_number_out.add_css_class ("stat-value-small");
            days_number_out.set_xalign (0.0f);
            r1top.append (days_number_out);
            r1.append (r1top);
            var r1label = new Gtk.Label (_("Days Journaled"));
            r1label.add_css_class ("stat-title");
            r1label.set_xalign (0.0f);
            r1.append (r1label);
            right_col.append (r1);

            var r2 = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) { halign = Gtk.Align.START };
            var r2top = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var quote_icon = new Gtk.Image.from_icon_name ("quote-symbolic");
            quote_icon.set_pixel_size (16);
            r2top.append (quote_icon);
            words_number_out = new Gtk.Label ("0");
            words_number_out.add_css_class ("stat-value-small");
            words_number_out.set_xalign (0.0f);
            r2top.append (words_number_out);
            r2.append (r2top);
            var r2label = new Gtk.Label (_("Total Words"));
            r2label.add_css_class ("stat-title");
            r2label.set_xalign (0.0f);
            r2.append (r2label);
            right_col.append (r2);

            content.append (right_col);

            return button;
        }

        private GLib.List<Tag?> sort_tags (GLib.List<Tag?> tags, string[] order) {
            var by_uuid = new GLib.HashTable<string, Tag?> (GLib.str_hash, GLib.str_equal);
            foreach (var t in tags) {
                if (t != null) {
                    by_uuid.insert (t.uuid, t);
                }
            }

            var used = new GLib.HashTable<string, bool> (GLib.str_hash, GLib.str_equal);
            var result = new GLib.List<Tag?> ();

            // First, add tags in the stored order if present
            foreach (var uuid in order) {
                if (by_uuid.contains (uuid)) {
                    var t = by_uuid.lookup (uuid);
                    if (t != null) {
                        result.append (t);
                        used.insert (uuid, true);
                    }
                }
            }

            // Then, append remaining tags in their original order
            foreach (var t in tags) {
                if (t != null && !used.contains (t.uuid)) {
                    result.append (t);
                }
            }

            return result;
        }

        private void setup_tag_dnd (TagRow row) {
            if (row.tag_uuid == null || row.tag_uuid == "deleted" || row.tag_uuid == "pinned" || row.tag_uuid == "all") {
                return; // only user-created tags are draggable
            }

            var source = new Gtk.DragSource ();
            source.set_actions (Gdk.DragAction.MOVE);
            source.prepare.connect ((x, y) => {
                var val = GLib.Value (typeof (string));
                val.set_string (row.tag_uuid);
                return new Gdk.ContentProvider.for_value (val);
            });
            row.add_controller (source);

            var drop = new Gtk.DropTarget (typeof (string), Gdk.DragAction.MOVE);
            drop.drop.connect ((value, x, y) => {
                if (!this.editing_mode)return false;

                var dragged_uuid = value.get_string ();
                if (dragged_uuid == null || row.tag_uuid == null)return false;
                if (dragged_uuid == row.tag_uuid)return false;

                return this.handle_tag_drop (dragged_uuid, row, y);
            });
            row.add_controller (drop);
        }

        private bool handle_tag_drop (string dragged_uuid, TagRow target_row, double y_in_row) {
            if (target_row.tag_uuid == null)return false;

            // Determine if drop should insert before or after the target row
            int min_h = 0;
            int nat_h = 0;
            int min_b = 0;
            int nat_b = 0;
            target_row.measure (Gtk.Orientation.VERTICAL, -1, out min_h, out nat_h, out min_b, out nat_b);
            int height = nat_h;
            bool insert_before = y_in_row < (height / 2.0);

            // Build current ordered list of user-created tag UUIDs
            var ordered_tags = sort_tags (this.data_manager.get_tags (), this.settings_manager.get_tag_order ());
            string[] ordered_uuids = {};
            foreach (var t in ordered_tags) {
                if (t != null) {
                    ordered_uuids += t.uuid;
                }
            }

            // Remove the dragged UUID
            string[] without_dragged = {};
            foreach (var u in ordered_uuids) {
                if (u != dragged_uuid) {
                    without_dragged += u;
                }
            }

            // Find target index
            int target_index = 0;
            for (int i = 0; i < without_dragged.length; i++) {
                if (without_dragged[i] == target_row.tag_uuid) {
                    target_index = i;
                    break;
                }
            }

            int insert_index = insert_before ? target_index : target_index + 1;

            // Build final order with the dragged UUID inserted at the desired position
            string[] final_order = {};
            for (int i = 0; i < without_dragged.length; i++) {
                if (i == insert_index) {
                    final_order += dragged_uuid;
                }
                final_order += without_dragged[i];
            }
            if (insert_index >= without_dragged.length) {
                final_order += dragged_uuid;
            }

            // Persist and refresh
            this.settings_manager.set_tag_order (final_order);
            this.refresh_tags ();
            return true;
        }

        private void toggle_editing_mode () {
            this.editing_mode = !this.editing_mode;
            update_edit_mode_ui ();
        }

        private void update_edit_mode_ui () {
            this.add_tag_button.set_sensitive (!editing_mode);
            // Keep edit button enabled to allow toggling edit mode on/off
            this.edit_button.set_sensitive (true);

            // Disable card buttons as pointer targets while editing so checkbuttons can be toggled


            // Show/hide card visibility switches while editing
            if (this.insights_switch != null) {
                this.insights_switch.set_visible (editing_mode);
            }
            if (this.places_switch != null) {
                this.places_switch.set_visible (editing_mode);
            }

            // While editing, force both cards to remain visible so their checkbuttons are accessible
            if (this.editing_mode) {
                this.insights_card_overlay.set_visible (true);
                this.places_card_overlay.set_visible (true);
            } else {
                // Apply saved visibility preferences when not editing
                this.insights_card_overlay.set_visible (settings_manager.get_insights_card_enabled ());
                this.places_card_overlay.set_visible (settings_manager.get_places_card_enabled ());
            }

            var _model = this.tag_list_box.observe_children ();
            for (uint i = 0; i < _model.get_n_items (); i++) {
                var child = _model.get_item (i) as Gtk.Widget;
                if (child is TagRow) {
                    var row = (TagRow) child;
                    row.set_editing (editing_mode);
                }
            }
        }
    }
}
