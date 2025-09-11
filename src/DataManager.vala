namespace Notejot {
    public class DataManager {

        public GLib.List<Tag?> tags = new GLib.List<Tag?> ();
        public GLib.List<Entry> entries = new GLib.List<Entry> ();
        private string tags_path;
        private string entries_path;
        private GLib.HashTable<string, string> tag_map;

        public DataManager() {
            var data_dir = GLib.Environment.get_user_data_dir();
            var app_dir = GLib.Path.build_filename(data_dir, "io.github.lainsce.Notejot");
            GLib.DirUtils.create_with_parents(app_dir, 0755);
            this.tags_path = GLib.Path.build_filename(app_dir, "tags.json");
            this.entries_path = GLib.Path.build_filename(app_dir, "entries.json");

            var old_dir = GLib.Path.build_filename(GLib.Environment.get_user_data_dir(), "io.github.lainsce.Notejot");
            var migration_flag = GLib.Path.build_filename(old_dir, ".notejot_migrated");

            if (!GLib.FileUtils.test(migration_flag, GLib.FileTest.EXISTS)) {
                migrate_old_format();
            }

            load_data();
        }

        public void add_tag(Tag tag) {
            this.tags.append(tag);
        }

        public void add_entry(Entry entry) {
            this.entries.append(entry);
        }

        public void delete_tag(string uuid) {
            Tag? tag_to_delete = null;
            foreach (var tag in this.tags) {
                if (tag.uuid == uuid) {
                    tag_to_delete = tag;
                    break;
                }
            }

            if (tag_to_delete != null) {
                this.tags.remove(tag_to_delete);

                // Remove the tag from all entries
                foreach (var entry in this.entries) {
                    entry.tag_uuids.remove(uuid);
                }
            }
        }

        public void delete_entry(Entry entry) {
            entry.is_deleted = true;
        }

        public void permanently_delete_entry(Entry entry) {
            this.entries.remove(entry);
        }

        public unowned GLib.List<Tag?> get_tags() {
            return this.tags;
        }

        public GLib.List<Entry?> get_entries(bool deleted_only = false) {
            var result = new GLib.List<Entry> ();
            foreach (var entry in this.entries) {
                if (entry.is_deleted == deleted_only) {
                    result.append(entry);
                }
            }
            return result;
        }

        public GLib.List<Entry?> get_entries_for_tag(string uuid) {
            var result = new GLib.List<Entry> ();
            foreach (var entry in this.entries) {
                if (!entry.is_deleted) {
                    foreach (var tag_uuid in entry.tag_uuids) {
                        if (tag_uuid == uuid) {
                            result.append(entry);
                            break;
                        }
                    }
                }
            }
            return result;
        }

        public GLib.List<Entry?> get_unique_locations() {
            var unique_locations = new GLib.List<Entry> ();
            var location_map = new GLib.HashTable<string, bool> (GLib.str_hash, GLib.str_equal);

            foreach (var entry in this.entries) {
                if (!entry.is_deleted && entry.latitude != null && entry.longitude != null) {
                    // Create a location key with rounded coordinates to handle slight GPS variations
                    var lat_rounded = Math.round(entry.latitude * 10000) / 10000;
                    var lon_rounded = Math.round(entry.longitude * 10000) / 10000;
                    var location_key = @"$lat_rounded,$lon_rounded";

                    if (!location_map.contains(location_key)) {
                        location_map.insert(location_key, true);
                        unique_locations.append(entry);
                    }
                }
            }
            return unique_locations;
        }

        public void save_data() {
            save_tags();
            save_entries();
        }

        private void save_tags() {
            var root = new Json.Array();
            foreach (var tag in this.tags) {
                root.add_object_element(tag.to_json());
            }
            var generator = new Json.Generator();
            generator.set_pretty(true);
            var root_node = new Json.Node(Json.NodeType.ARRAY);
            root_node.set_array(root);
            generator.set_root(root_node);
            try {
                string? data = generator.to_data(null);
                GLib.FileUtils.set_contents(this.tags_path, data);
            } catch (GLib.Error e) {
                warning("Failed to save tags: %s", e.message);
            }
        }

        private void save_entries() {
            var root = new Json.Array();
            foreach (var entry in this.entries) {
                root.add_object_element(entry.to_json());
            }
            var generator = new Json.Generator();
            generator.set_pretty(true);
            var root_node = new Json.Node(Json.NodeType.ARRAY);
            root_node.set_array(root);
            generator.set_root(root_node);
            try {
                string? data = generator.to_data(null);
                GLib.FileUtils.set_contents(this.entries_path, data);
            } catch (GLib.Error e) {
                warning("Failed to save entries: %s", e.message);
            }
        }

        public void load_data() {
            load_tags();
            load_entries();
        }

        private void load_tags() {
            try {
                string contents;
                GLib.FileUtils.get_contents(this.tags_path, out contents);
                var parser = new Json.Parser();
                parser.load_from_data(contents);
                var root = parser.get_root().get_array();
                foreach (var node in root.get_elements()) {
                    var tag = Tag.from_json(node.get_object());
                    this.tags.append(tag);
                }
            } catch (GLib.Error e) {
                // File probably doesn't exist, which is fine on first run
            }
        }

        private void load_entries() {
            try {
                string contents;
                GLib.FileUtils.get_contents(this.entries_path, out contents);
                var parser = new Json.Parser();
                parser.load_from_data(contents);
                var root = parser.get_root().get_array();
                foreach (var node in root.get_elements()) {
                    var entry = Entry.from_json(node.get_object());
                    this.entries.append(entry);
                }
            } catch (GLib.Error e) {
                // File probably doesn't exist, which is fine on first run
            }
        }

        private void migrate_old_format() {
            var old_dir = GLib.Path.build_filename(GLib.Environment.get_user_data_dir(), "io.github.lainsce.Notejot");
            var notes_file = GLib.Path.build_filename(old_dir, "saved_notes.json");
            if (!GLib.FileUtils.test(notes_file, GLib.FileTest.EXISTS))
                return;


            // Load old JSON
            try {
                var nb_parser = new Json.Parser();
                nb_parser.load_from_file(GLib.Path.build_filename(old_dir, "saved_notebooks.json"));
                var notes_parser = new Json.Parser();
                notes_parser.load_from_file(notes_file);
                var trash_parser = new Json.Parser();
                trash_parser.load_from_file(GLib.Path.build_filename(old_dir, "saved_trash.json"));

                var notebooks_array = nb_parser.get_root().get_array();
                var notes_array = notes_parser.get_root().get_array();
                var trash_array = trash_parser.get_root().get_array();

                // Map notebooks -> Tags
                tag_map = new GLib.HashTable<string, string> (GLib.str_hash, GLib.str_equal);
                foreach (var nb_node in notebooks_array.get_elements()) {
                    var nb = nb_node.get_object();
                    var tag = new Notejot.Tag.full(
                                                   nb.get_string_member("id"),
                                                   nb.get_string_member("title"),
                                                   "#ffd54f", // default
                                                   null
                    );
                    this.add_tag(tag);
                    tag_map.insert(nb.get_string_member("title"), tag.uuid);
                }

                import_notes(notes_array, false);
                import_notes(trash_array, true);
            } catch (GLib.Error e) {
                warning("Failed to load old files: %s", e.message);
            }

            // Save everything into new backend
            this.save_data();

            // Flag migration done
            try {
                GLib.FileUtils.set_contents(GLib.Path.build_filename(old_dir, ".notejot_migrated"), "done");
            } catch (GLib.FileError e) {
                warning("Failed to set migration flag: %s", e.message);
            }


            // Rename old files after migration
            string[] old_files = {
                "saved_notes.json",
                "saved_notebooks.json",
                "saved_trash.json"
            };

            foreach (var fname in old_files) {
                var old_path = GLib.Path.build_filename(old_dir, fname);
                if (GLib.FileUtils.test(old_path, GLib.FileTest.EXISTS)) {
                    var new_path = old_path.replace(".json", "_migrated.json");
                    GLib.FileUtils.rename(old_path, new_path);
                }
            }
        }

        // Try parsing legacy subtitle datetime
        int64 parse_subtitle_timestamp(string subtitle) {

            // Example subtitle: "Monday, 08/09 16∶28"
            // Skip weekday and parse as MM/DD HH:MM
            var parts = subtitle.split(",", 2);
            if (parts.length == 2) {
                var trimmed = parts[1].strip(); // "08/09 16∶28"
                var now_year = new GLib.DateTime.now_local().get_year();
                var dt = new GLib.DateTime.now_local().format("%m/%d %H∶%M");
                if (dt != null) {
                    // attach current year
                    // Parse the trimmed string as "MM/DD HH:MM"
                    int month = 1, day = 1, hour = 0, minute = 0;
                    var date_time_parts = trimmed.split(" ");
                    if (date_time_parts.length == 2) {
                        var md = date_time_parts[0].split("/");
                        if (md.length == 2) {
                            month = int.parse(md[0]);
                            day = int.parse(md[1]);
                        }
                        var hm = date_time_parts[1].replace("∶", ":").split(":");
                        if (hm.length == 2) {
                            hour = int.parse(hm[0]);
                            minute = int.parse(hm[1]);
                        }
                    }
                    var dt_obj = new GLib.DateTime.local(now_year, month, day, hour, minute, 0.0);
                    return dt_obj.to_unix();
                }
            }
            return new GLib.DateTime.now_utc().to_unix();
        }

        // Import notes helper
        void import_notes(Json.Array arr, bool trashed) {
            foreach (var nt_node in arr.get_elements()) {
                var nt = nt_node.get_object();

                // Build content: color first line + original text
                var color_line = "[Color: " + nt.get_string_member("color") + "]";
                var content = color_line + "\n" + nt.get_string_member("text");

                var tags = new GLib.List<string> ();
                if (nt.has_member("notebook")) {
                    var nb_title = nt.get_string_member("notebook");
                    var tag_uuid = tag_map.lookup(nb_title);
                    if (tag_uuid != null) {
                        tags.append(tag_uuid);
                    }
                }

                var images = new GLib.List<string> ();
                if (nt.has_member("picture") && nt.get_string_member("picture") != "") {
                    images.append(nt.get_string_member("picture"));
                }

                var timestamp = nt.has_member("subtitle") ?
                    parse_subtitle_timestamp(nt.get_string_member("subtitle")) :
                    new GLib.DateTime.now_utc().to_unix();

                var entry = new Notejot.Entry.full(
                                                   nt.get_string_member("id"),
                                                   nt.get_string_member("title"),
                                                   content,
                                                   timestamp, // creation_timestamp
                                                   timestamp, // modified_timestamp
                                                   tags,
                                                   null, // no location info
                                                   null,
                                                   null,
                                                   images,
                                                   trashed
                );

                this.add_entry(entry);
            }
        }
    }
}
