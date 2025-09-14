namespace Notejot {
    public class Tag {
        public string uuid;
        public string name;
        public string color;
        public string? icon_name;

        // Constructor for a new tag, generates a UUID automatically.
        public Tag(string name, string color, string? icon_name = null) {
            this.uuid = GLib.Uuid.string_random();
            this.name = name;
            this.color = color;
            this.icon_name = icon_name;
        }

        // Constructor for loading from file.
        public Tag.full(string uuid, string name, string color, string? icon_name) {
            this.uuid = uuid;
            this.name = name;
            this.color = color;
            this.icon_name = icon_name;
        }

        // Serializes the Tag object to a JSON object.
        public Json.Object to_json() {
            var obj = new Json.Object();
            obj.set_string_member("uuid", this.uuid);
            obj.set_string_member("name", this.name);
            obj.set_string_member("color", this.color);
            if (this.icon_name != null) {
                obj.set_string_member("icon_name", this.icon_name);
            }
            return obj;
        }

        // Deserializes a JSON object into a Tag object.
        public static Tag from_json(Json.Object obj) {
            return new Tag.full(
                                obj.get_string_member("uuid"),
                                obj.get_string_member("name"),
                                obj.get_string_member("color"),
                                obj.has_member("icon_name") ? obj.get_string_member("icon_name") : null
            );
        }
    }

    public class Entry {
        public string uuid { get; private set; }
        public string title { get; set; }
        public string content { get; set; }
        public GLib.DateTime date { get; set; }
        public int64 creation_timestamp { get; set; }
        public int64 modified_timestamp { get; set; }
        public GLib.List<string> tag_uuids = new GLib.List<string> ();
        public string? location_address { get; set; }
        public double? latitude { get; set; }
        public double? longitude { get; set; }
        public GLib.List<string> image_paths = new GLib.List<string> ();
        public bool is_deleted { get; set; }
        public bool is_pinned { get; set; }


        public Entry(string title, string content, GLib.List<string> tag_uuids, GLib.List<string>? image_paths) {
            var now = new GLib.DateTime.now_utc();
            this.uuid = GLib.Uuid.string_random();
            this.title = title;
            this.content = content;
            this.date = now.to_local();
            this.creation_timestamp = now.to_unix();
            this.modified_timestamp = now.to_unix();
            foreach (var uuid in tag_uuids) {
                this.tag_uuids.append(uuid);
            }
            foreach (var path in image_paths) {
                this.image_paths.append(path);
            }
            this.is_deleted = false;
            this.is_pinned = false;
        }

        // Constructor for loading from file
        public Entry.full(string uuid, string title, string content, int64 creation_timestamp, int64 modified_timestamp, GLib.List<string> tag_uuids, string? location_address, double? latitude, double? longitude, GLib.List<string> image_paths, bool is_deleted, bool is_pinned) {
            this.uuid = uuid;
            this.title = title;
            this.content = content;
            this.creation_timestamp = creation_timestamp;
            this.modified_timestamp = modified_timestamp;
            this.date = new GLib.DateTime.from_unix_local(creation_timestamp);
            foreach (var vuuid in tag_uuids) {
                this.tag_uuids.append(vuuid);
            }
            this.location_address = location_address;
            this.latitude = latitude;
            this.longitude = longitude;
            foreach (var path in image_paths) {
                this.image_paths.append(path);
            }
            this.is_deleted = is_deleted;
            this.is_pinned = is_pinned;
        }

        public async void geocode_location() {
            if (this.location_address == null || this.location_address.strip() == "")
                return;

            // Static variable to remember last request time
            int64 last_request_time = 0;

            // Enforce 1-second interval
            var now = new GLib.DateTime.now_utc().to_unix();
            if (now - last_request_time < 1) {
                // Sleep until one second passes
                GLib.Timeout.add(1000, () => false);
                GLib.Thread.usleep(1000000); // 1 second in microseconds
            }
            last_request_time = new GLib.DateTime.now_utc().to_unix();

            try {
                var session = new Soup.Session();

                var encoded = GLib.Uri.escape_string(this.location_address, null, false);
                var url = "https://nominatim.openstreetmap.org/search?format=json&limit=1&q=" + encoded;

                var msg = new Soup.Message("GET", url);
                // REQUIRED by Nominatim usage policy
                msg.request_headers.append("User-Agent", "Notejot/1.0");

                // Fetch complete response body
                var bytes = yield session.send_and_read_async(msg, GLib.Priority.DEFAULT, null);

                // Parse JSON as string
                var response_str = (string) bytes.get_data();

                var parser = new Json.Parser();
                parser.load_from_data(response_str);

                var root = parser.get_root().get_array();
                if (root.get_length() > 0) {
                    var obj = root.get_element(0).get_object();
                    this.latitude = double.parse(obj.get_string_member("lat"));
                    this.longitude = double.parse(obj.get_string_member("lon"));
                }
            } catch (Error e) {
                warning("Direct geocoding failed for '%s': %s", this.location_address, e.message);
            }
        }

        // Serializes the Entry object to a JSON object.
        public Json.Object to_json() {
            var obj = new Json.Object();
            obj.set_string_member("uuid", this.uuid);
            obj.set_string_member("title", this.title);
            obj.set_string_member("content", this.content);
            obj.set_int_member("creation_timestamp", this.creation_timestamp);
            obj.set_int_member("modified_timestamp", this.modified_timestamp);
            if (this.location_address != null) {
                obj.set_string_member("location_address", this.location_address);
            }
            if (this.latitude != null) {
                obj.set_double_member("latitude", (double) this.latitude);
            }
            if (this.longitude != null) {
                obj.set_double_member("longitude", (double) this.longitude);
            }

            var tags_array = new Json.Array();
            foreach (var uuid in this.tag_uuids) {
                tags_array.add_string_element(uuid);
            }
            obj.set_array_member("tag_uuids", tags_array);

            var images_array = new Json.Array();
            foreach (var path in this.image_paths) {
                images_array.add_string_element(path);
            }
            obj.set_array_member("image_paths", images_array);

            obj.set_boolean_member("is_deleted", this.is_deleted);
            obj.set_boolean_member("is_pinned", this.is_pinned);
            return obj;
        }

        // Deserializes a JSON object into an Entry object.
        public static Entry from_json(Json.Object obj) {
            var image_paths = new GLib.List<string> ();
            if (obj.has_member("image_paths")) {
                var images_array = obj.get_array_member("image_paths");
                foreach (var element in images_array.get_elements()) {
                    image_paths.append(element.get_string());
                }
            }

            var tag_uuids = new GLib.List<string> ();
            if (obj.has_member("tag_uuids")) {
                var tags_array = obj.get_array_member("tag_uuids");
                foreach (var element in tags_array.get_elements()) {
                    tag_uuids.append(element.get_string());
                }
            }

            return new Entry.full(
                                  obj.get_string_member("uuid"),
                                  obj.get_string_member("title"),
                                  obj.get_string_member("content"),
                                  (long) obj.get_int_member("creation_timestamp"),
                                  (long) obj.get_int_member("modified_timestamp"),
                                  tag_uuids,
                                  obj.has_member("location_address") ? obj.get_string_member("location_address") : null,
                                  obj.has_member("latitude") ? (double?) obj.get_double_member("latitude") : null,
                                  obj.has_member("longitude") ? (double?) obj.get_double_member("longitude") : null,
                                  image_paths,
                                  obj.get_boolean_member("is_deleted"),
                                  obj.has_member("is_pinned") ? obj.get_boolean_member("is_pinned") : false
            );
        }
    }
}
