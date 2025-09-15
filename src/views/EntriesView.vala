namespace Notejot {
    public class EntriesView : Gtk.Box {

        public signal void entry_selected_for_edit (Entry entry);
        public signal void entry_deleted (Entry entry);
        public signal void entry_restored (Entry entry);
        public signal void list_updated (int count, string? search_query);


        private DataManager data_manager;
        private Gtk.ListBox entry_list_box;
        private Gtk.Label current_tag_header;
        private Gtk.SearchEntry? search_entry = null;
        private string? current_tag_uuid = null;

        public EntriesView (DataManager data_manager) {
            Object (
                    orientation : Gtk.Orientation.VERTICAL,
                    spacing: 0
            );
            this.data_manager = data_manager;

            this.set_hexpand (true);
            this.add_css_class ("main-content");

            var appbar = new He.AppBar ();
            appbar.show_left_title_buttons = false;
            this.append (appbar);

            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            header_box.set_margin_end (18);
            header_box.set_margin_bottom (12);
            this.append (header_box);

            this.current_tag_header = new Gtk.Label (_("All Entries")) { halign = Gtk.Align.START };
            this.current_tag_header.add_css_class ("header");
            header_box.append (this.current_tag_header);

            var spacer = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) { hexpand = true };
            header_box.append (spacer);

            this.search_entry = new Gtk.SearchEntry ();
            this.search_entry.set_placeholder_text (_("Search entries…"));
            this.search_entry.search_changed.connect (() => {
                this.refresh_list ();
                this.search_entry.grab_focus ();
            });
            header_box.append (this.search_entry);
            this.search_entry.remove_css_class ("disclosure-button");
            this.search_entry.add_css_class ("search");
            this.search_entry.add_css_class ("text-field");

            // Entry List
            var scrolled_entries = new Gtk.ScrolledWindow ();
            scrolled_entries.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolled_entries.set_vexpand (true);
            this.entry_list_box = new Gtk.ListBox () { selection_mode = Gtk.SelectionMode.NONE };
            this.entry_list_box.add_css_class ("entry-list");
            scrolled_entries.set_child (this.entry_list_box);
            this.append (scrolled_entries);
        }

        public void set_current_tag (string? tag_uuid, string display_name) {
            this.current_tag_uuid = tag_uuid;
            this.current_tag_header.set_label (display_name);
            refresh_list ();
        }

        public void refresh_list () {
            while (entry_list_box.get_first_child () != null) {
                entry_list_box.remove (entry_list_box.get_first_child ());
            }

            var entries_to_show = new GLib.List<Entry> ();
            if (this.current_tag_uuid == "deleted") {
                entries_to_show = this.data_manager.get_entries (true);
            } else if (this.current_tag_uuid == "pinned") {
                entries_to_show = this.data_manager.get_pinned_entries ();
            } else if (this.current_tag_uuid == "") {
                entries_to_show = this.data_manager.get_entries (false);
            } else {
                entries_to_show = this.data_manager.get_entries_for_tag (this.current_tag_uuid);
            }

            string? q = null;
            if (this.search_entry != null) {
                q = this.search_entry.get_text ().strip ();
            }
            if (q != null) {
                try {
                    var pattern = GLib.Regex.escape_string (q, -1);
                    var regex = new GLib.Regex (pattern, GLib.RegexCompileFlags.CASELESS | GLib.RegexCompileFlags.OPTIMIZE, 0);

                    var filtered = new GLib.List<Entry> ();
                    foreach (var entry in entries_to_show) {
                        var t = entry.title != null ? entry.title : "";
                        var c = entry.content != null ? entry.content : "";
                        if (regex.match (t) || regex.match (c)) {
                            filtered.append (entry);
                        }
                    }
                    filtered.sort ((a, b) => {
                        if (a.creation_timestamp > b.creation_timestamp)return -1;
                        if (a.creation_timestamp < b.creation_timestamp)return 1;
                        return 0;
                    });
                    entries_to_show = filtered.copy_deep ((a) => { return a; });
                } catch (Error e) {
                    // keep unfiltered list on regex failure
                }
            }

            list_updated ((int) entries_to_show.length (), q);

            if (entries_to_show.length () > 0) {
                var now = new GLib.DateTime.now_local ();
                var today = now.format ("%Y-%m-%d");
                var yesterday = now.add_days (-1).format ("%Y-%m-%d");

                string? last_date_label = null;

                foreach (var entry in entries_to_show) {
                    var entry_date = entry.date.format ("%Y-%m-%d");

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

            string[] lines = entry.content.split ("\n");
            string preview_content = "";
            int max_lines = 3;
            for (int i = 0; i < lines.length && i < max_lines; i++) {
                preview_content += lines[i];
                if (i < max_lines - 1 && i < lines.length - 1) {
                    preview_content += "\n";
                }
            }
            var content = new Gtk.Label (preview_content) { xalign = 0.0f, wrap = true };
            content.add_css_class ("content");
            content.set_hexpand (true);
            text_box.append (content);

            if (entry.tag_uuids.length () > 0) {
                var tags_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
                tags_row.set_halign (Gtk.Align.START);
                tags_row.margin_start = 18;
                foreach (var tag_uuid in entry.tag_uuids) {
                    Tag? tag = null;
                    foreach (var t in this.data_manager.get_tags ()) {
                        if (t.uuid == tag_uuid) {
                            tag = t;
                            break;
                        }
                    }
                    if (tag != null) {
                        var chip_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                        chip_box.add_css_class ("tag-chip");
                        if (tag.color != null && tag.color != "") {
                            string color_class = "";
                            if (tag.color != null && tag.color != "") {
                                string color_name = "";
                                switch (tag.color) {
                                case "#e57373" :
                                    color_name = "red";
                                    break;
                                case "#f06292":
                                    color_name = "pink";
                                    break;
                                case "#ba68c8":
                                    color_name = "purple";
                                    break;
                                case "#7986cb":
                                    color_name = "indigo";
                                    break;
                                case "#64b5f6":
                                    color_name = "blue";
                                    break;
                                case "#32ade6":
                                    color_name = "cyan";
                                    break;
                                case "#4dd0e1":
                                    color_name = "teal";
                                    break;
                                case "#4db6ac":
                                    color_name = "mint";
                                    break;
                                case "#81c784":
                                    color_name = "green";
                                    break;
                                case "#ffd54f":
                                    color_name = "yellow";
                                    break;
                                case "#ffb74d":
                                    color_name = "orange";
                                    break;
                                case "#bcaaa4":
                                    color_name = "brown";
                                    break;
                                default:
                                    break;
                                }
                                color_class = "tag-chip-" + color_name;
                            }
                            chip_box.add_css_class (color_class);
                        }
                        if (tag.icon_name != null && tag.icon_name != "") {
                            var icon = new Gtk.Image.from_icon_name (tag.icon_name);
                            icon.set_pixel_size (14);
                            chip_box.append (icon);
                        }
                        var tag_chip = new Gtk.Label (tag.name);
                        chip_box.append (tag_chip);
                        chip_box.set_valign (Gtk.Align.CENTER);
                        tags_row.append (chip_box);
                    }
                }
                text_box.append (tags_row);
            }

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

            var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            actions_box.set_halign (Gtk.Align.END);
            actions_box.margin_end = 18;
            actions_box.margin_top = 12;
            box.append (actions_box);

            if (this.current_tag_uuid != "deleted") {
                var pin_button = new Gtk.ToggleButton ();
                pin_button.add_css_class ("entry-pin-button");
                pin_button.set_halign (Gtk.Align.CENTER);
                pin_button.set_valign (Gtk.Align.CENTER);
                pin_button.set_active (entry.is_pinned);

                if (pin_button.get_active ()) {
                    pin_button.set_icon_name ("user-bookmarks-filled-symbolic");
                    pin_button.set_tooltip_text (_("Remove Bookmark"));
                } else {
                    pin_button.set_icon_name ("user-bookmarks-symbolic");
                    pin_button.set_tooltip_text (_("Add Bookmark"));
                }

                pin_button.toggled.connect (() => {
                    entry.is_pinned = pin_button.get_active ();
                    this.data_manager.save_data ();
                    if (this.current_tag_uuid == "pinned" && !entry.is_pinned) {
                        this.refresh_list ();
                    }

                    if (pin_button.get_active ()) {
                        pin_button.set_icon_name ("user-bookmarks-filled-symbolic");
                        pin_button.set_tooltip_text (_("Remove Bookmark"));
                    } else {
                        pin_button.set_icon_name ("user-bookmarks-symbolic");
                        pin_button.set_tooltip_text (_("Add Bookmark"));
                    }
                });
                actions_box.append (pin_button);
            }

            var menu_button = new Gtk.MenuButton ();
            menu_button.add_css_class ("entry-menu-button");
            var icon = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic");
            menu_button.set_child (icon);
            menu_button.set_halign (Gtk.Align.END);
            menu_button.set_valign (Gtk.Align.CENTER);
            menu_button.get_popover ().has_arrow = false;
            actions_box.append (menu_button);

            var menu_model = new Menu ();
            if (this.current_tag_uuid == "deleted") {
                var restore_item = new MenuItem (_("Restore"), "entry.restore");
                menu_model.append_item (restore_item);
                var delete_item = new MenuItem (_("Delete Permanently"), "entry.delete");
                menu_model.append_item (delete_item);
            } else {
                var edit_item = new MenuItem (_("Edit"), "entry.edit");
                menu_model.append_item (edit_item);
                var delete_item = new MenuItem (_("Delete"), "entry.delete");
                menu_model.append_item (delete_item);
            }
            menu_button.set_menu_model (menu_model);

            var action_group = new SimpleActionGroup ();
            var edit_action = new SimpleAction ("edit", null);
            edit_action.activate.connect (() => {
                entry_selected_for_edit (entry);
            });
            action_group.add_action (edit_action);

            var delete_action = new SimpleAction ("delete", null);
            delete_action.activate.connect (() => {
                entry_deleted (entry);
            });
            action_group.add_action (delete_action);

            var restore_action = new SimpleAction ("restore", null);
            restore_action.activate.connect (() => {
                entry_restored (entry);
            });
            action_group.add_action (restore_action);

            box.insert_action_group ("entry", action_group);

            var row = new Gtk.ListBoxRow ();
            row.set_child (box);
            return row;
        }
    }
}
