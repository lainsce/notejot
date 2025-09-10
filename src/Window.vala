namespace Notejot {
    public class Window : He.ApplicationWindow {
        private const GLib.ActionEntry APP_ENTRIES[] = {
            { "edit-entry", on_edit_entry_clicked },
            { "delete-entry", on_delete_entry_clicked },
        };
        private DataManager data_manager;
        private InsightsView insights_view;
        private PlacesView places_view;

        private He.OverlayButton fab;
        private Gtk.Box main_content_container;
        private Gtk.Box entries_view;
        private Gtk.ScrolledWindow scrolled_entries;
        private Gtk.Box empty_state_view;
        private Gtk.Box deleted_empty_state_view;

        private Gtk.Label current_tag_header;
        private Gtk.ListBox entry_list_box;

        private Gtk.ListBox tag_list_box;
        private Gtk.Label insights_subtitle;
        private Gtk.Label places_subtitle;

        private string? current_tag_uuid = null; // null means "All Entries" here
        private Entry? selected_entry = null; // Track the currently selected entry

        public Window (He.Application app) {
            Object (application : app, title: _("Notejot"));
            this.data_manager = new DataManager ();

            this.set_default_size (1024, 830);

            var main_paned = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.set_child (main_paned);
            // --- Sidebar ---
            setup_sidebar (main_paned);
            // --- Main Content Area Container ---
            this.main_content_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.main_content_container.set_hexpand (true);
            main_paned.append (this.main_content_container);

            // --- Main Content Stack ---
            setup_entries_view ();
            setup_empty_state_view ();
            setup_deleted_empty_state_view ();
            this.insights_view = new InsightsView (this.data_manager);
            this.places_view = new PlacesView (this.data_manager);
            // --- FAB (only for entries view) ---
            fab = new He.OverlayButton ("list-add-symbolic", null, null);
            fab.clicked.connect (on_add_entry_clicked);
            fab.child = this.entries_view;

            // Initially show entries view with FAB
            this.main_content_container.append (fab);
            refresh_sidebar_tags ();
            update_stats ();

            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (APP_ENTRIES, this);
            this.insert_action_group ("win", actions);

            this.present ();
        }

        private void setup_sidebar (Gtk.Box main_paned) {
            var sidebar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            sidebar_box.set_size_request (260, -1);
            sidebar_box.set_hexpand_set (false);
            sidebar_box.set_hexpand (false);
            sidebar_box.add_css_class ("sidebar");
            main_paned.append (sidebar_box);

            var appbar = new He.AppBar ();
            appbar.show_right_title_buttons = false;
            appbar.set_size_request (285, -1);
            sidebar_box.append (appbar);

            var insights_button = create_sidebar_card (
                                                       _("Insights"), _("0 Entries This Year"), "insights-card", out this.insights_subtitle
            );
            insights_button.clicked.connect (() => {
                switch_to_view ("insights");
                tag_list_box.unselect_all ();
            });
            sidebar_box.append (insights_button);

            var places_button = create_sidebar_card (
                                                     _("Places"), _("0 Locations"), "places-card", out this.places_subtitle
            );
            places_button.clicked.connect (() => {
                switch_to_view ("places");
                tag_list_box.unselect_all ();
            });
            sidebar_box.append (places_button);

            var tags_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            tags_header_box.add_css_class ("tags-header");
            tags_header_box.set_size_request (285, -1);
            sidebar_box.append (tags_header_box);
            var tags_label = new Gtk.Label (_("Tags")) { hexpand = true, halign = Gtk.Align.START };
            tags_header_box.append (tags_label);
            var add_tag_button = new He.Button ("list-add-symbolic", "");
            add_tag_button.is_disclosure = true;
            add_tag_button.clicked.connect (on_add_tag_clicked);
            tags_header_box.append (add_tag_button);
            var scrolled_tags = new Gtk.ScrolledWindow () { vexpand = true };
            scrolled_tags.set_size_request (285, -1);
            scrolled_tags.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            sidebar_box.append (scrolled_tags);
            this.tag_list_box = new Gtk.ListBox ();
            this.tag_list_box.add_css_class ("sidebar-list");
            this.tag_list_box.set_selection_mode (Gtk.SelectionMode.SINGLE);
            this.tag_list_box.row_selected.connect (on_tag_selected);
            scrolled_tags.set_child (this.tag_list_box);
        }

        private void setup_entries_view () {
            this.entries_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.entries_view.set_hexpand (true);
            this.entries_view.add_css_class ("main-content");

            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            entries_view.append (appbar);
            this.current_tag_header = new Gtk.Label (_("All Entries")) { halign = Gtk.Align.START };
            this.current_tag_header.add_css_class ("header");
            this.entries_view.append (this.current_tag_header);
            // Entry List
            this.scrolled_entries = new Gtk.ScrolledWindow ();
            this.scrolled_entries.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            this.scrolled_entries.set_vexpand (true);
            this.entry_list_box = new Gtk.ListBox () { selection_mode = Gtk.SelectionMode.NONE };
            this.entry_list_box.add_css_class ("entry-list");
            this.scrolled_entries.set_child (this.entry_list_box);
            this.entries_view.append (this.scrolled_entries);
        }

        private void setup_empty_state_view () {
            this.empty_state_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.empty_state_view.set_hexpand (true);
            this.empty_state_view.add_css_class ("main-content");

            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            empty_state_view.append (appbar);
            var current_tag_header_empty = new Gtk.Label (_("No Entries")) { halign = Gtk.Align.START };
            current_tag_header_empty.add_css_class ("header");
            this.empty_state_view.append (current_tag_header_empty);
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
            add_first_entry_button.clicked.connect (on_add_entry_clicked);
            empty_content_box.append (add_first_entry_button);

            this.empty_state_view.append (empty_content_box);
        }

        private void setup_deleted_empty_state_view () {
            this.deleted_empty_state_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.deleted_empty_state_view.set_hexpand (true);
            this.deleted_empty_state_view.add_css_class ("main-content");

            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            deleted_empty_state_view.append (appbar);
            var current_tag_header_deleted = new Gtk.Label (_("Recently Deleted")) { halign = Gtk.Align.START };
            current_tag_header_deleted.add_css_class ("header");
            this.deleted_empty_state_view.append (current_tag_header_deleted);
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

            this.deleted_empty_state_view.append (deleted_content_box);
        }

        private void switch_to_view (string view_name) {
            // Remove current child
            var current_child = this.main_content_container.get_first_child ();
            if (current_child != null) {
                this.main_content_container.remove (current_child);
            }

            // Add appropriate view
            if (view_name == "entries") {
                // Use FAB overlay for entries
                this.main_content_container.append (fab);
                fab.child = this.entries_view;
            } else if (view_name == "empty") {
                // Direct view without FAB for empty state
                this.main_content_container.append (this.empty_state_view);
            } else if (view_name == "deleted-empty") {
                // Direct view without FAB for deleted empty state
                this.main_content_container.append (this.deleted_empty_state_view);
            } else {
                // Direct view without FAB for insights and places
                if (view_name == "insights") {
                    this.main_content_container.append (this.insights_view);
                } else if (view_name == "places") {
                    this.main_content_container.append (this.places_view);
                }
            }
        }

        private Gtk.Button create_sidebar_card (string title, string subtitle, string style_class, out Gtk.Label subtitle_label_out) {
            var button = new Gtk.Button ();
            button.add_css_class ("card");
            button.add_css_class (style_class);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) { halign = Gtk.Align.START };
            button.set_child (box);
            var title_label = new Gtk.Label (title);
            title_label.add_css_class ("title");
            title_label.set_xalign (0.0f);
            box.append (title_label);

            subtitle_label_out = new Gtk.Label (subtitle);
            subtitle_label_out.add_css_class ("subtitle");
            subtitle_label_out.set_xalign (0.0f);
            box.append (subtitle_label_out);

            return button;
        }

        private void refresh_sidebar_tags () {
            while (this.tag_list_box.get_first_child () != null) {
                this.tag_list_box.remove (this.tag_list_box.get_first_child ());
            }

            // All Entries
            var all_entries_row = new TagRow (null, _("All Entries"), data_manager.get_entries (false).length ().to_string (), "user-home-symbolic", null);
            this.tag_list_box.append (all_entries_row);

            // User-created tags
            foreach (var tag in this.data_manager.get_tags ()) {
                var row = new TagRow (tag.color, tag.name, data_manager.get_entries_for_tag (tag.uuid).length ().to_string (), tag.icon_name, tag.uuid);
                row.deleted.connect ((uuid) => {
                    this.data_manager.delete_tag (uuid);
                    this.data_manager.save_data ();
                    this.refresh_sidebar_tags ();
                    this.refresh_entry_list ();
                    this.update_stats ();
                });
                row.edit_requested.connect ((uuid) => {
                    // Find the tag by uuid
                    Tag? found = null;
                    foreach (var t in this.data_manager.get_tags ()) {
                        if (t.uuid == uuid) { found = t; break; }
                    }
                    if (found == null)return;

                    var dialog = new AddTagDialog (this, true);
                    dialog.name_entry.get_internal_entry ().text = found.name;
                    dialog.set_selected_color (found.color);
                    dialog.set_selected_icon_name (found.icon_name);
                    dialog.present ();
                    dialog.response.connect ((response_id) => {
                        if (response_id == Gtk.ResponseType.ACCEPT) {
                            var new_name = dialog.name_entry.get_internal_entry ().text;
                            if (new_name != "") {
                                found.name = new_name;
                                var chosen_color = dialog.get_selected_color ();
                                if (chosen_color == "#ffd54f" && found.color != "#ffd54f") {
                                    chosen_color = found.color;
                                }
                                found.color = chosen_color;

                                var chosen_icon = dialog.get_selected_icon_name ();
                                if (chosen_icon == null && found.icon_name != null) {
                                    chosen_icon = found.icon_name;
                                }
                                found.icon_name = chosen_icon;
                                this.data_manager.save_data ();
                                this.refresh_sidebar_tags ();
                                this.refresh_entry_list ();
                                this.update_stats ();
                            }
                        }
                        dialog.destroy ();
                    });
                });
                this.tag_list_box.append (row);
            }

            // Recently Deleted
            var deleted_row = new TagRow (null, _("Recently Deleted"), data_manager.get_entries (true).length ().to_string (), "user-trash-symbolic", "deleted");
            this.tag_list_box.append (deleted_row);

            this.tag_list_box.select_row (this.tag_list_box.get_row_at_index (0));
        }

        private void on_tag_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            if (row is TagRow) {
                var tag_row = (TagRow) row;
                this.current_tag_uuid = tag_row.tag_uuid;
                this.current_tag_header.set_label (tag_row.display_name);

                // Update empty state header labels to match
                var empty_header = this.empty_state_view.get_first_child ().get_next_sibling () as Gtk.Label;
                if (empty_header != null) {
                    empty_header.set_label (tag_row.display_name);
                }

                refresh_entry_list ();
            }
        }

        private void refresh_entry_list () {
            while (entry_list_box.get_first_child () != null) {
                entry_list_box.remove (entry_list_box.get_first_child ());
            }

            var entries_to_show = new GLib.List<Entry> ();
            if (this.current_tag_uuid == "deleted") {
                entries_to_show = this.data_manager.get_entries (true);
            } else if (this.current_tag_uuid == null) {
                entries_to_show = this.data_manager.get_entries (false);
            } else {
                entries_to_show = this.data_manager.get_entries_for_tag (this.current_tag_uuid);
            }

            if (entries_to_show.length () == 0) {
                if (this.current_tag_uuid == "deleted") {
                    switch_to_view ("deleted-empty");
                } else {
                    switch_to_view ("empty");
                }
            } else {
                switch_to_view ("entries");
                // Group entries by date
                var now = new GLib.DateTime.now_local ();
                var today = now.format ("%Y-%m-%d");
                var yesterday = now.add_days (-1).format ("%Y-%m-%d");

                string? last_date_label = null;

                foreach (var entry in entries_to_show) {
                    var entry_date = entry.date.format ("%Y-%m-%d");

                    // Add a date label if the date changes
                    if (last_date_label == null || last_date_label != entry_date) {
                        string date_label_text;
                        if (entry_date == today) {
                            date_label_text = _("Today");
                        } else if (entry_date == yesterday) {
                            date_label_text = _("Yesterday");
                        } else {
                            date_label_text = entry.date.format ("%A, %B %d");
                        }

                        var date_label = new Gtk.Label (date_label_text) { halign = Gtk.Align.START };
                        date_label.add_css_class ("date-label");
                        this.entry_list_box.append (date_label);

                        last_date_label = entry_date;
                    }

                    var entry_card = create_entry_card (entry);
                    this.entry_list_box.append (entry_card);
                }
            }
        }

        private Gtk.ListBoxRow create_entry_card (Entry entry) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            box.add_css_class ("entry-card");

            var main_content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            main_content_box.set_hexpand (true);

            var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            text_box.set_hexpand (true);
            var image_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            image_box.set_hexpand (true);

            var title = new Gtk.Label (entry.title) { xalign = 0.0f, wrap = true };
            title.add_css_class ("entry-header");
            text_box.append (title);

            var date = new Gtk.Label (entry.date.format ("%A, %B %d")) { xalign = 0.0f };
            date.add_css_class ("date");
            text_box.append (date);

            var content = new Gtk.Label (entry.content) { xalign = 0.0f, wrap = true };
            content.add_css_class ("content");
            content.set_hexpand (true);
            text_box.append (content);

            // Image grid on the right
            if (entry.image_paths.length () > 0) {
                var image_grid = new Gtk.Grid ();
                image_grid.set_row_spacing (6);
                image_grid.set_column_spacing (6);
                image_grid.set_halign (Gtk.Align.END);
                image_grid.set_valign (Gtk.Align.START);
                image_grid.set_margin_end (18);

                int image_count = 0;
                foreach (var image_path in entry.image_paths) {
                    if (image_count >= 4)break;
                    var image = new Gtk.Image ();
                    image.set_pixel_size (64);
                    image.set_halign (Gtk.Align.CENTER);
                    image.set_valign (Gtk.Align.CENTER);
                    image.set_vexpand (true);
                    try {
                        var pixbuf = new Gdk.Pixbuf.from_file_at_scale (image_path, 64, 64, true);
                        var texture = Gdk.Texture.for_pixbuf (pixbuf);
                        image.set_from_paintable (texture);
                    } catch (Error e) {
                        // If image can't be loaded, skip it
                        continue;
                    }

                    var image_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                    image_container.set_size_request (72, 72);
                    image_container.add_css_class ("entry-thumbnail");
                    image_container.append (image);

                    int row = image_count / 2;
                    int col = image_count % 2;
                    image_grid.attach (image_container, col, row, 1, 1);

                    image_count++;
                }

                image_box.append (image_grid);
            }

            main_content_box.append (text_box);
            main_content_box.append (image_box);
            box.append (main_content_box);
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.margin_top = 12;
            box.append (separator);

            var menu_button = new Gtk.MenuButton ();
            menu_button.add_css_class ("entry-menu-button");
            var icon = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic");
            menu_button.set_child (icon);
            menu_button.set_halign (Gtk.Align.END);
            menu_button.get_popover ().has_arrow = false;
            box.append (menu_button);
            var edit_action = new SimpleAction ("edit-entry-" + entry.uuid, null);
            edit_action.activate.connect (() => {
                this.selected_entry = entry;
                on_edit_entry_clicked ();
            });
            var delete_action = new SimpleAction ("delete-entry-" + entry.uuid, null);
            delete_action.activate.connect (() => {
                this.selected_entry = entry;
                on_delete_entry_clicked ();
            });
            var action_group = new SimpleActionGroup ();
            action_group.add_action (edit_action);
            action_group.add_action (delete_action);
            box.insert_action_group ("entry", action_group);

            var menu_model = new Menu ();
            menu_model.append (_("Edit"), "entry.edit-entry-" + entry.uuid);
            menu_model.append (_("Delete"), "entry.delete-entry-" + entry.uuid);
            menu_button.set_menu_model (menu_model);

            var row = new Gtk.ListBoxRow ();
            row.set_child (box);
            return row;
        }

        private void update_stats () {
            int year_count = 0;
            int location_count = 0;
            var now = new GLib.DateTime.now_local ();
            foreach (var entry in this.data_manager.get_entries (false)) {
                if (entry.date.get_year () == now.get_year ()) {
                    year_count++;
                }
                if (entry.latitude != null && entry.longitude != null) {
                    location_count++;
                }
            }
            this.insights_subtitle.set_label (@"$year_count Entries This Year");
            this.places_subtitle.set_label (@"$location_count Locations");

            if (this.insights_view != null)this.insights_view.update_view ();
            if (this.places_view != null)this.places_view.refresh_pins ();
        }

        private void on_add_tag_clicked () {
            var dialog = new AddTagDialog (this, false);
            dialog.present ();

            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    var name = dialog.name_entry.get_internal_entry ().text;
                    if (name != "") {
                        var new_tag = new Tag (name, dialog.get_selected_color (), dialog.get_selected_icon_name ());
                        this.data_manager.add_tag (new_tag);
                        this.data_manager.save_data ();
                        this.refresh_sidebar_tags ();
                    }
                }
                dialog.destroy ();
            });
        }

        private void save_entry_and_refresh (Entry entry, bool is_new_entry) {
            if (is_new_entry) {
                this.data_manager.add_entry (entry);
            }
            this.data_manager.save_data ();
            this.refresh_sidebar_tags ();
            this.refresh_entry_list ();
            this.update_stats ();
        }

        private async void save_entry_with_geocode (Entry entry, bool is_new_entry) {
            yield entry.geocode_location ();

            save_entry_and_refresh (entry, is_new_entry);
        }

        private void on_edit_entry_clicked () {
            if (this.selected_entry == null)return;
            var entry = this.selected_entry;
            var dialog = new AddEntryDialog (this, this.data_manager, entry);
            dialog.present ();
            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    var title = dialog.title_entry.get_internal_entry ().text;
                    var content = dialog.get_content ();
                    var address = dialog.location_entry.get_internal_entry ().text;

                    if (title != "" || content != "") {
                        entry.title = title;
                        entry.content = content;
                        entry.tag_uuids = dialog.get_selected_tag_uuids ();
                        entry.location_address = address;

                        foreach (var path in dialog.image_paths) {
                            entry.image_paths.append (path);
                        }

                        save_entry_with_geocode.begin (entry, false);
                    }
                }
                dialog.destroy ();
            });
        }

        private void on_delete_entry_clicked () {
            if (this.selected_entry == null)return;
            var entry = this.selected_entry;

            if (this.current_tag_uuid == "deleted") {
                // Permanently delete if in trash
                this.data_manager.permanently_delete_entry (entry);
            } else {
                // Move to trash
                this.data_manager.delete_entry (entry);
            }

            this.data_manager.save_data ();
            this.refresh_sidebar_tags ();
            this.refresh_entry_list ();
            this.update_stats ();
        }

        private void on_add_entry_clicked () {
            // Don't allow adding entries when in "Recently Deleted" section
            if (this.current_tag_uuid == "deleted") {
                return;
            }

            var dialog = new AddEntryDialog (this, this.data_manager, null);
            // If a specific tag is selected (not "All Entries"), prepopulate it
            if (this.current_tag_uuid != null) {
                var tag_uuids = new GLib.List<string> ();
                tag_uuids.append (this.current_tag_uuid);
                dialog.set_preselected_tags (tag_uuids);
            }

            dialog.present ();
            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    var title = dialog.title_entry.get_internal_entry ().text;
                    var content = dialog.get_content ();
                    var address = dialog.location_entry.get_internal_entry ().text;

                    if (title != "" || content != "") {
                        var tag_uuids = dialog.get_selected_tag_uuids ();

                        // If viewing a specific tag, add it to the list if not already there
                        if (this.current_tag_uuid != null && this.current_tag_uuid != "deleted") {
                            bool found = false;
                            foreach (var uuid in tag_uuids) {
                                if (uuid == this.current_tag_uuid) {
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) {
                                tag_uuids.append (this.current_tag_uuid);
                            }
                        }

                        var new_entry = new Entry (title, content, tag_uuids, null);
                        new_entry.location_address = address;

                        foreach (var path in dialog.image_paths) {
                            new_entry.image_paths.append (path);
                        }

                        save_entry_with_geocode.begin (new_entry, true);
                    }
                }
                dialog.destroy ();
            });
        }
    }
}
