namespace Notejot {
    public class Sidebar : Gtk.Box {
        public signal void view_switched (string view_name);
        public signal void tag_selected (string? tag_uuid, string display_name);
        public signal void add_tag_clicked ();
        public signal void settings_clicked ();
        public signal void edit_tag_requested (string uuid);

        private DataManager data_manager;

        private Gtk.ListBox tag_list_box;

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

            this.set_size_request (320, -1);
            this.set_hexpand_set (false);
            this.set_hexpand (false);
            this.add_css_class ("sidebar");

            var appbar = new He.AppBar ();
            appbar.show_right_title_buttons = false;
            appbar.set_size_request (320, -1);
            this.append (appbar);

            // Settings button in the sidebar AppBar
            var settings_button = new He.Button ("open-menu-symbolic", "");
            settings_button.tooltip_text = _("Open Settings…");
            settings_button.is_disclosure = true;
            settings_button.set_halign (Gtk.Align.END);
            settings_button.set_margin_end (12);
            settings_button.set_margin_bottom (6);
            settings_button.clicked.connect (() => {
                settings_clicked ();
            });
            this.append (settings_button);

            // Insights card with detailed contents
            var insights_button = create_insights_card (out this.insights_year_number_label,
                                                        out this.insights_days_number_label,
                                                        out this.insights_words_number_label);
            insights_button.clicked.connect (() => {
                view_switched ("insights");
                tag_list_box.unselect_all ();
            });
            this.append (insights_button);

            // Places card (keeps existing simple counter)
            var places_button = create_sidebar_card (
                                                     _("Places"),
                                                     _("0 Locations"),
                                                     "places-card",
                                                     out this.places_subtitle_number
            );
            places_button.set_size_request (-1, 148);
            places_button.clicked.connect (() => {
                view_switched ("places");
                tag_list_box.unselect_all ();
            });
            this.append (places_button);

            var tags_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            tags_header_box.add_css_class ("tags-header");
            tags_header_box.set_size_request (320, -1);
            this.append (tags_header_box);
            var tags_label = new Gtk.Label (_("Tags")) { hexpand = true, halign = Gtk.Align.START };
            tags_label.add_css_class ("header");
            tags_header_box.append (tags_label);
            var add_tag_button = new He.Button ("list-add-symbolic", "");
            add_tag_button.tooltip_text = _("Add Tag…");
            add_tag_button.is_disclosure = true;
            add_tag_button.clicked.connect (() => {
                add_tag_clicked ();
            });
            tags_header_box.append (add_tag_button);
            var scrolled_tags = new Gtk.ScrolledWindow () { vexpand = true };
            scrolled_tags.set_size_request (320, -1);
            scrolled_tags.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            this.append (scrolled_tags);
            this.tag_list_box = new Gtk.ListBox ();
            this.tag_list_box.add_css_class ("sidebar-list");
            this.tag_list_box.set_selection_mode (Gtk.SelectionMode.SINGLE);
            this.tag_list_box.row_selected.connect (on_tag_selected);
            scrolled_tags.set_child (this.tag_list_box);
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
            var all_entries_row = new TagRow (null, _("All Entries"), data_manager.get_entries (false).length ().to_string (), "user-home-symbolic", null);
            this.tag_list_box.append (all_entries_row);

            // Bookmarks
            var pinned_entries = data_manager.get_pinned_entries ();
            if (pinned_entries.length () > 0) {
                var bookmarks_row = new TagRow (null, _("Bookmarks"), pinned_entries.length ().to_string (), "user-bookmarks-symbolic", "pinned");
                this.tag_list_box.append (bookmarks_row);
            }

            // User-created tags
            foreach (var tag in this.data_manager.get_tags ()) {
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
            }

            // Recently Deleted
            var deleted_row = new TagRow (null, _("Recently Deleted"), data_manager.get_entries (true).length ().to_string (), "user-trash-symbolic", "deleted");
            this.tag_list_box.append (deleted_row);

            this.tag_list_box.select_row (this.tag_list_box.get_row_at_index (0));
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

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) { halign = Gtk.Align.START };
            button.set_child (box);

            var title_label = new Gtk.Label (title);
            title_label.add_css_class ("title");
            title_label.set_xalign (0.0f);
            box.append (title_label);

            string number = "0";
            string label = subtitle;

            int space_index = subtitle.index_of (" ");
            if (space_index > 0) {
                number = subtitle.substring (0, space_index);
                label = subtitle.substring (space_index + 1);
            }

            number_label_out = new Gtk.Label (number);
            number_label_out.add_css_class ("stat-value");
            number_label_out.set_xalign (0.0f);
            box.append (number_label_out);

            string label_markup = label;
            var subtitle_label_out = new Gtk.Label (label_markup);
            subtitle_label_out.add_css_class ("stat-title");
            subtitle_label_out.set_xalign (0.0f);
            subtitle_label_out.set_use_markup (true);
            subtitle_label_out.set_max_width_chars (12);
            subtitle_label_out.set_wrap (true);
            box.append (subtitle_label_out);

            return button;
        }

        private Gtk.Button create_insights_card (out Gtk.Label year_number_out,
                                                 out Gtk.Label days_number_out,
                                                 out Gtk.Label words_number_out) {
            var button = new Gtk.Button ();
            button.add_css_class ("card");
            button.add_css_class ("insights-card");

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) { halign = Gtk.Align.START };
            button.set_child (root);

            var title_label = new Gtk.Label (_("Insights"));
            title_label.add_css_class ("title");
            title_label.set_xalign (0.0f);
            root.append (title_label);

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
    }
}
