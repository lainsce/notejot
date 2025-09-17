namespace Notejot {
    public class DataManager : GLib.Object {

        public GLib.List<Tag?> tags = new GLib.List<Tag?> ();
        public GLib.List<Entry> entries = new GLib.List<Entry> ();
        private string tags_path;
        private string entries_path;
        private string app_dir;
        private string media_dir;
        private GLib.HashTable<string, string> tag_map;
        // Remote sync monitoring
        private GLib.FileMonitor? remote_tags_monitor = null;
        private GLib.FileMonitor? remote_entries_monitor = null;
        private GLib.FileMonitor? remote_media_monitor = null;
        private int64 last_push_time = 0;

        public DataManager() {
            var data_dir = GLib.Environment.get_user_data_dir();
            this.app_dir = GLib.Path.build_filename(data_dir, "io.github.lainsce.Notejot");
            GLib.DirUtils.create_with_parents(this.app_dir, 0755);
            this.media_dir = GLib.Path.build_filename(this.app_dir, "media");
            GLib.DirUtils.create_with_parents(this.media_dir, 0755);
            this.tags_path = GLib.Path.build_filename(this.app_dir, "tags.json");
            this.entries_path = GLib.Path.build_filename(this.app_dir, "entries.json");

            var old_dir = GLib.Path.build_filename(GLib.Environment.get_user_data_dir(), "io.github.lainsce.Notejot");
            var migration_flag = GLib.Path.build_filename(old_dir, ".notejot_migrated");

            if (!GLib.FileUtils.test(migration_flag, GLib.FileTest.EXISTS)) {
                migrate_old_format();
            }

            sync_pull_if_enabled();
            load_data();

            // React to settings changes: ensure monitors are set and try to push/pull
            var settings = SettingsManager.get_default();
            settings.changed.connect(() => {
                sync_pull_if_enabled();
                sync_push_if_enabled();
            });
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

        public void restore_entry(Entry entry) {
            entry.is_deleted = false;
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
            // Sort by creation timestamp, most recent first
            result.sort((a, b) => {
                if (a.creation_timestamp > b.creation_timestamp)return -1;
                if (a.creation_timestamp < b.creation_timestamp)return 1;
                return 0;
            });
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
            // Sort by creation timestamp, most recent first
            result.sort((a, b) => {
                if (a.creation_timestamp > b.creation_timestamp)return -1;
                if (a.creation_timestamp < b.creation_timestamp)return 1;
                return 0;
            });
            return result;
        }

        public GLib.List<Entry?> get_pinned_entries() {
            var result = new GLib.List<Entry> ();
            foreach (var entry in this.entries) {
                if (entry.is_pinned && !entry.is_deleted) {
                    result.append(entry);
                }
            }
            // Sort by creation timestamp, most recent first
            result.sort((a, b) => {
                if (a.creation_timestamp > b.creation_timestamp)return -1;
                if (a.creation_timestamp < b.creation_timestamp)return 1;
                return 0;
            });
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
            sync_push_if_enabled();
        }

        public void sync_push() {
            sync_push_if_enabled();
        }

        public void sync_pull() {
            sync_pull_if_enabled();
        }

        public void cleanup_media() {
            // Delete files in local media dir that are not referenced by any entry
            try {
                var used = new GLib.HashTable<string, bool>(GLib.str_hash, GLib.str_equal);
                foreach (var e in this.entries) {
                    foreach (var p in e.image_paths) {
                        if (p != null && p.strip() != "") {
                            var file_base = GLib.Path.get_basename(p);
                            used.insert(file_base, true);
                        }
                    }
                }
                var dir = File.new_for_path(this.media_dir);
                if (dir.query_exists()) {
                    var en = dir.enumerate_children("standard::name", FileQueryInfoFlags.NONE, null);
                    FileInfo info;
                    while ((info = en.next_file(null)) != null) {
                        var name = info.get_name();
                        if (name == null || name == "") continue;
                        if (!used.contains(name)) {
                            try {
                                var f = File.new_for_path(GLib.Path.build_filename(this.media_dir, name));
                                f.delete();
                            } catch (Error fe) {
                                // ignore
                            }
                        }
                    }
                }
            } catch (Error e) {
                // ignore
            }
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

        // Nextcloud-like folder sync: two-way merge pull + set up monitors
        private void sync_pull_if_enabled() {
            var settings = SettingsManager.get_default();
            if (!settings.get_sync_enabled()) return;

            var sync_base = settings.get_sync_folder_path();
            if (sync_base == null || sync_base.strip() == "") return;

            var sync_dir = GLib.Path.build_filename(sync_base, "Notejot");
            try {
                GLib.DirUtils.create_with_parents(sync_dir, 0755);
            } catch (GLib.Error e) {
                // ignore; we'll still try to read below
            }

            var src_tags = GLib.Path.build_filename(sync_dir, "tags.json");
            var src_entries = GLib.Path.build_filename(sync_dir, "entries.json");
            var remote_media_dir = GLib.Path.build_filename(sync_dir, "media");
            try {
                GLib.DirUtils.create_with_parents(remote_media_dir, 0755);
            } catch (GLib.Error e) {
            }

            // Build Json arrays for local and remote (missing -> empty arrays)
            var local_tags_arr = new Json.Array();
            var local_entries_arr = new Json.Array();
            var remote_tags_arr = new Json.Array();
            var remote_entries_arr = new Json.Array();

            // Load local
            try {
                if (GLib.FileUtils.test(this.tags_path, GLib.FileTest.EXISTS)) {
                    string contents;
                    GLib.FileUtils.get_contents(this.tags_path, out contents);
                    if (contents != null && contents.strip() != "") {
                        var parser = new Json.Parser();
                        parser.load_from_data(contents);
                        if (parser.get_root().get_node_type() == Json.NodeType.ARRAY) {
                            local_tags_arr = parser.get_root().get_array();
                        }
                    }
                }
            } catch (GLib.Error e) {}
            try {
                if (GLib.FileUtils.test(this.entries_path, GLib.FileTest.EXISTS)) {
                    string contents;
                    GLib.FileUtils.get_contents(this.entries_path, out contents);
                    if (contents != null && contents.strip() != "") {
                        var parser = new Json.Parser();
                        parser.load_from_data(contents);
                        if (parser.get_root().get_node_type() == Json.NodeType.ARRAY) {
                            local_entries_arr = parser.get_root().get_array();
                        }
                    }
                }
            } catch (GLib.Error e) {}

            // Load remote
            try {
                if (GLib.FileUtils.test(src_tags, GLib.FileTest.EXISTS)) {
                    string contents;
                    GLib.FileUtils.get_contents(src_tags, out contents);
                    if (contents != null && contents.strip() != "") {
                        var parser = new Json.Parser();
                        parser.load_from_data(contents);
                        if (parser.get_root().get_node_type() == Json.NodeType.ARRAY) {
                            remote_tags_arr = parser.get_root().get_array();
                        }
                    }
                }
            } catch (GLib.Error e) {
                warning("Sync pull (tags) failed: %s", e.message);
            }
            try {
                if (GLib.FileUtils.test(src_entries, GLib.FileTest.EXISTS)) {
                    string contents;
                    GLib.FileUtils.get_contents(src_entries, out contents);
                    if (contents != null && contents.strip() != "") {
                        var parser = new Json.Parser();
                        parser.load_from_data(contents);
                        if (parser.get_root().get_node_type() == Json.NodeType.ARRAY) {
                            remote_entries_arr = parser.get_root().get_array();
                        }
                    }
                }
            } catch (GLib.Error e) {
                warning("Sync pull (entries) failed: %s", e.message);
            }

            // Merge Tags (uuid union; on conflict prefer remote)
            var tag_by_uuid_local = new GLib.HashTable<string, Tag> (GLib.str_hash, GLib.str_equal);
            var tag_by_uuid_remote = new GLib.HashTable<string, Tag> (GLib.str_hash, GLib.str_equal);

            foreach (var n in local_tags_arr.get_elements()) {
                var t = Tag.from_json(n.get_object());
                tag_by_uuid_local.insert(t.uuid, t);
            }
            foreach (var n in remote_tags_arr.get_elements()) {
                var t = Tag.from_json(n.get_object());
                tag_by_uuid_remote.insert(t.uuid, t);
            }

            var merged_tags = new Json.Array();
            // add all remote (preferred)
            foreach (var n in remote_tags_arr.get_elements()) {
                merged_tags.add_object_element(Tag.from_json(n.get_object()).to_json());
            }
            // add locals not present remotely
            foreach (var n in local_tags_arr.get_elements()) {
                var t = Tag.from_json(n.get_object());
                if (!tag_by_uuid_remote.contains(t.uuid)) {
                    merged_tags.add_object_element(t.to_json());
                }
            }

            // Merge Entries (uuid union; conflict -> choose higher modified_timestamp)
            var entry_by_uuid_local = new GLib.HashTable<string, Entry> (GLib.str_hash, GLib.str_equal);
            var entry_by_uuid_remote = new GLib.HashTable<string, Entry> (GLib.str_hash, GLib.str_equal);

            foreach (var n in local_entries_arr.get_elements()) {
                var e = Entry.from_json(n.get_object());
                entry_by_uuid_local.insert(e.uuid, e);
            }
            foreach (var n in remote_entries_arr.get_elements()) {
                var e = Entry.from_json(n.get_object());
                entry_by_uuid_remote.insert(e.uuid, e);
            }

            var merged_entries = new Json.Array();
            // First pass: for all uuids in remote, decide winner
            foreach (var n in remote_entries_arr.get_elements()) {
                var re = Entry.from_json(n.get_object());
                Entry? winner = re;
                if (entry_by_uuid_local.contains(re.uuid)) {
                    var le = entry_by_uuid_local.lookup(re.uuid);
                    if (le != null) {
                        if (le.modified_timestamp > re.modified_timestamp) {
                            winner = le;
                        }
                    }
                }
                merged_entries.add_object_element(winner.to_json());
            }
            // Second pass: add locals not present in remote
            foreach (var n in local_entries_arr.get_elements()) {
                var le = Entry.from_json(n.get_object());
                if (!entry_by_uuid_remote.contains(le.uuid)) {
                    merged_entries.add_object_element(le.to_json());
                }
            }

            // Write merged arrays to local files
            try {
                var gen = new Json.Generator();
                gen.set_pretty(true);
                var node = new Json.Node(Json.NodeType.ARRAY);
                node.set_array(merged_tags);
                gen.set_root(node);
                string? data = gen.to_data(null);
                GLib.FileUtils.set_contents(this.tags_path, data);
            } catch (GLib.Error e) {
                warning("Sync pull: failed writing merged tags: %s", e.message);
            }
            try {
                var gen = new Json.Generator();
                gen.set_pretty(true);
                var node = new Json.Node(Json.NodeType.ARRAY);
                node.set_array(merged_entries);
                gen.set_root(node);
                string? data = gen.to_data(null);
                GLib.FileUtils.set_contents(this.entries_path, data);
            } catch (GLib.Error e) {
                warning("Sync pull: failed writing merged entries: %s", e.message);
            }

            // Pull media from remote/media to local media dir (best-effort)
            try {
                var rdir = File.new_for_path(remote_media_dir);
                if (rdir.query_exists()) {
                    var enumerator = rdir.enumerate_children("standard::name", FileQueryInfoFlags.NONE, null);
                    FileInfo info;
                    while ((info = enumerator.next_file(null)) != null) {
                        var name = info.get_name();
                        if (name == null || name == "") continue;
                        var src = File.new_for_path(GLib.Path.build_filename(remote_media_dir, name));
                        var dst = File.new_for_path(GLib.Path.build_filename(this.media_dir, name));
                        try {
                            if (!dst.query_exists()) {
                                src.copy(dst, FileCopyFlags.OVERWRITE, null, null);
                            }
                        } catch (Error e) {
                            // ignore copy failure per file
                        }
                    }
                }
            } catch (Error e) {
                // ignore
            }

            // Reload in-memory lists if already initialized
            if (this.tags != null || this.entries != null) {
                // Reset lists and load again
                this.tags = new GLib.List<Tag?> ();
                this.entries = new GLib.List<Entry> ();
                load_data();
            }

            // Set up file monitors once
            try {
                if (this.remote_tags_monitor == null) {
                    var f = File.new_for_path(src_tags);
                    this.remote_tags_monitor = f.monitor_file(FileMonitorFlags.NONE, null);
                    this.remote_tags_monitor.changed.connect((mon, file, other, event) => {
                        // Avoid reacting immediately after our own push
                        var now = new GLib.DateTime.now_utc().to_unix();
                        if (now - this.last_push_time <= 2) return;
                        sync_pull_if_enabled();
                    });
                }
                if (this.remote_entries_monitor == null) {
                    var f = File.new_for_path(src_entries);
                    this.remote_entries_monitor = f.monitor_file(FileMonitorFlags.NONE, null);
                    this.remote_entries_monitor.changed.connect((mon, file, other, event) => {
                        var now = new GLib.DateTime.now_utc().to_unix();
                        if (now - this.last_push_time <= 2) return;
                        sync_pull_if_enabled();
                    });
                }
                if (this.remote_media_monitor == null) {
                    var f = File.new_for_path(remote_media_dir);
                    this.remote_media_monitor = f.monitor_directory(FileMonitorFlags.NONE, null);
                    this.remote_media_monitor.changed.connect((mon, file, other, event) => {
                        var now = new GLib.DateTime.now_utc().to_unix();
                        if (now - this.last_push_time <= 2) return;
                        // Copy any new or modified media
                        try {
                            var rel = file.get_basename();
                            if (rel != null && rel != "") {
                                var src = File.new_for_path(GLib.Path.build_filename(remote_media_dir, rel));
                                var dst = File.new_for_path(GLib.Path.build_filename(this.media_dir, rel));
                                if (!dst.query_exists() || event == FileMonitorEvent.CHANGED) {
                                    src.copy(dst, FileCopyFlags.OVERWRITE, null, null);
                                }
                            }
                        } catch (Error e) {
                        }
                    });
                }
            } catch (Error e) {
                // ignore monitor errors
            }
        }

        // Nextcloud-like folder sync: push local data and media to remote folder (on save)
        private void sync_push_if_enabled() {
            var settings = SettingsManager.get_default();
            if (!settings.get_sync_enabled()) return;

            var sync_base = settings.get_sync_folder_path();
            if (sync_base == null || sync_base.strip() == "") return;

            var sync_dir = GLib.Path.build_filename(sync_base, "Notejot");
            var remote_media_dir = GLib.Path.build_filename(sync_dir, "media");
            try {
                GLib.DirUtils.create_with_parents(sync_dir, 0755);
                GLib.DirUtils.create_with_parents(remote_media_dir, 0755);
            } catch (GLib.Error e) {
                // If we cannot ensure the directory, abort push.
                warning("Sync push: cannot create directory '%s': %s", sync_dir, e.message);
                return;
            }

            var dst_tags = GLib.Path.build_filename(sync_dir, "tags.json");
            var dst_entries = GLib.Path.build_filename(sync_dir, "entries.json");

            try {
                string contents;
                GLib.FileUtils.get_contents(this.tags_path, out contents);
                GLib.FileUtils.set_contents(dst_tags, contents);
            } catch (GLib.Error e) {
                warning("Sync push (tags) failed: %s", e.message);
            }

            try {
                string contents;
                GLib.FileUtils.get_contents(this.entries_path, out contents);
                GLib.FileUtils.set_contents(dst_entries, contents);
            } catch (GLib.Error e) {
                warning("Sync push (entries) failed: %s", e.message);
            }

            // Copy referenced media files
            try {
                foreach (var e in this.entries) {
                    foreach (var p in e.image_paths) {
                        if (p == null || p.strip() == "") continue;
                        try {
                            var base_name = GLib.Path.get_basename(p);
                            var src = File.new_for_path(p);
                            var dst = File.new_for_path(GLib.Path.build_filename(remote_media_dir, base_name));
                            // Always overwrite remote to keep it fresh
                            src.copy(dst, FileCopyFlags.OVERWRITE, null, null);
                        } catch (Error ce) {
                            // ignore per-file error
                        }
                    }
                }
            } catch (Error e) {
            }

            // Record push time to avoid reacting to our own monitor events
            this.last_push_time = new GLib.DateTime.now_utc().to_unix();
        }

        private void migrate_old_format() {
            var old_dir = GLib.Path.build_filename(GLib.Environment.get_user_data_dir(), "io.github.lainsce.Notejot");
            var notes_file = GLib.Path.build_filename(old_dir, "saved_notes.json");
            var pinned_notes_file = GLib.Path.build_filename(old_dir, "saved_pinned_notes.json");
            if (!GLib.FileUtils.test(notes_file, GLib.FileTest.EXISTS))
                return;
            if (!GLib.FileUtils.test(pinned_notes_file, GLib.FileTest.EXISTS))
                return;

            // Load old JSON
            try {
                var nb_parser = new Json.Parser();
                nb_parser.load_from_file(GLib.Path.build_filename(old_dir, "saved_notebooks.json"));
                var notes_parser = new Json.Parser();
                notes_parser.load_from_file(notes_file);
                var pinned_notes_parser = new Json.Parser();
                pinned_notes_parser.load_from_file(pinned_notes_file);
                var trash_parser = new Json.Parser();
                trash_parser.load_from_file(GLib.Path.build_filename(old_dir, "saved_trash.json"));

                var notebooks_array = nb_parser.get_root().get_array();
                var notes_array = notes_parser.get_root().get_array();
                var pinned_notes_array = pinned_notes_parser.get_root().get_array();
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

                import_notes(notes_array, false, false);
                import_notes(pinned_notes_array, false, true);
                import_notes(trash_array, true, false);
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
                "saved_pinned_notes.json",
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
        void import_notes(Json.Array arr, bool trashed, bool pinned) {
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
                                                   timestamp, // creation_timestamp
                                                   tags,
                                                   null, // no location info
                                                   null,
                                                   null,
                                                   images,
                                                   trashed,
                                                   pinned
                );

                this.add_entry(entry);
            }
        }
    }
}
