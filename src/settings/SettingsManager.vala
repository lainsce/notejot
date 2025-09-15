/*
 * SettingsManager.vala
 *
 * Persists user preferences for:
 * - Scheduling: day(s) of week + time for weekly reminders
 * - Streak reminder: time for daily reminder
 *
 * Data is stored as JSON at:
 *   $XDG_DATA_HOME/io.github.lainsce.Notejot/settings.json
 *
 * JSON shape (version 1):
 * {
 *   "version": 1,
 *   "scheduling": {
 *     "enabled": true,
 *     "time": "09:00",
 *     "days_of_week": [1, 3, 5] // 1=Mon ... 7=Sun (GLib.DateTime convention)
 *   },
 *   "streak": {
 *     "enabled": true,
 *     "time": "20:00"
 *   },
 *   "sidebar": {
 *      "insights_card_enabled": true,
 *      "places_card_enabled": true,
 *      "tag_order": []
 *   }
 * }
 */

using Json;

namespace Notejot {

    public class SettingsManager : GLib.Object {
        // Emitted whenever save() succeeds and preferences have changed.
        public signal void changed ();

        // Paths
        private string settings_path;

        // Internal data (defaults)
        private bool scheduling_enabled = false;
        private string scheduling_time = "09:00"; // 24h HH:MM
        private int[]  scheduling_days = {}; // 1..7 (Mon..Sun)

        private bool streak_enabled = false;
        private string streak_time = "20:00"; // 24h HH:MM

        private bool insights_card_enabled = true;
        private bool places_card_enabled = true;
        private string[] tag_order = {};

        // Singleton
        private static SettingsManager? instance = null;

        public static SettingsManager get_default () {
            if (instance == null) {
                instance = new SettingsManager ();
            }
            return instance;
        }

        public SettingsManager () {
            // Ensure app data dir exists and compute path
            var data_dir = GLib.Environment.get_user_data_dir ();
            var app_dir = GLib.Path.build_filename (data_dir, "io.github.lainsce.Notejot");
            GLib.DirUtils.create_with_parents (app_dir, 0755);

            this.settings_path = GLib.Path.build_filename (app_dir, "settings.json");

            // Load if exists, otherwise keep defaults
            load ();
        }

        // ---- Public getters -------------------------------------------------

        public bool get_scheduling_enabled () {
            return this.scheduling_enabled;
        }

        public string get_scheduling_time () {
            return this.scheduling_time;
        }

        // Returns copy of days array to avoid accidental external mutation
        public int[] get_scheduling_days_of_week () {
            int[] out_days = {};
            foreach (var d in this.scheduling_days) {
                out_days += d;
            }
            return out_days;
        }

        public bool get_streak_enabled () {
            return this.streak_enabled;
        }

        public string get_streak_time () {
            return this.streak_time;
        }

        public bool get_insights_card_enabled () {
            return this.insights_card_enabled;
        }

        public bool get_places_card_enabled () {
            return this.places_card_enabled;
        }

        public string[] get_tag_order () {
            return this.tag_order;
        }

        // ---- Public setters (auto-save) ------------------------------------

        public void set_scheduling_enabled (bool enabled) {
            if (this.scheduling_enabled == enabled)return;
            this.scheduling_enabled = enabled;
            save ();
        }

        public void set_scheduling_time (string time_hhmm) {
            var normalized = normalize_time_or_fallback (time_hhmm, this.scheduling_time);
            if (this.scheduling_time == normalized)return;
            this.scheduling_time = normalized;
            save ();
        }

        // Accepts any number of days; values outside 1..7 are ignored.
        // Duplicates are removed. Order is normalized ascending 1..7.
        public void set_scheduling_days_of_week (int[] days) {
            var sanitized = sanitize_days (days);
            if (arrays_equal (this.scheduling_days, sanitized))return;
            this.scheduling_days = sanitized;
            save ();
        }

        public void set_streak_enabled (bool enabled) {
            if (this.streak_enabled == enabled)return;
            this.streak_enabled = enabled;
            save ();
        }

        public void set_streak_time (string time_hhmm) {
            var normalized = normalize_time_or_fallback (time_hhmm, this.streak_time);
            if (this.streak_time == normalized)return;
            this.streak_time = normalized;
            save ();
        }

        public void set_insights_card_enabled (bool enabled) {
            if (this.insights_card_enabled == enabled)return;
            this.insights_card_enabled = enabled;
            save ();
        }

        public void set_places_card_enabled (bool enabled) {
            if (this.places_card_enabled == enabled)return;
            this.places_card_enabled = enabled;
            save ();
        }

        public void set_tag_order (string[] order) {
            this.tag_order = order;
            save ();
        }

        // Convenience batch updates (auto-save)
        public void update_scheduling (bool enabled, string time_hhmm, int[] days_of_week) {
            this.scheduling_enabled = enabled;
            this.scheduling_time = normalize_time_or_fallback (time_hhmm, this.scheduling_time);
            this.scheduling_days = sanitize_days (days_of_week);
            save ();
        }

        public void update_streak (bool enabled, string time_hhmm) {
            this.streak_enabled = enabled;
            this.streak_time = normalize_time_or_fallback (time_hhmm, this.streak_time);
            save ();
        }

        // ---- Persistence ----------------------------------------------------

        private void load () {
            if (!GLib.FileUtils.test (this.settings_path, GLib.FileTest.EXISTS)) {
                return; // keep defaults
            }

            string contents;
            GLib.FileUtils.get_contents (this.settings_path, out contents);

            var parser = new Json.Parser ();
            parser.load_from_data (contents);
            var root_node = parser.get_root ();
            if (root_node.get_node_type () != Json.NodeType.OBJECT)return;

            var root = root_node.get_object ();

            // Scheduling
            if (root.has_member ("scheduling")) {
                var sched = root.get_object_member ("scheduling");

                if (sched.has_member ("enabled")) {
                    this.scheduling_enabled = sched.get_boolean_member ("enabled");
                }
                if (sched.has_member ("time")) {
                    var t = sched.get_string_member ("time");
                    this.scheduling_time = normalize_time_or_fallback (t, this.scheduling_time);
                }
                if (sched.has_member ("days_of_week")) {
                    var arr = sched.get_array_member ("days_of_week");
                    int[] tmp = {};
                    foreach (var el in arr.get_elements ()) {
                        int v = (int) el.get_int ();
                        tmp += v;
                    }
                    this.scheduling_days = sanitize_days (tmp);
                }
            }

            // Streak
            if (root.has_member ("streak")) {
                var st = root.get_object_member ("streak");

                if (st.has_member ("enabled")) {
                    this.streak_enabled = st.get_boolean_member ("enabled");
                }
                if (st.has_member ("time")) {
                    var t = st.get_string_member ("time");
                    this.streak_time = normalize_time_or_fallback (t, this.streak_time);
                }
            }

            // Sidebar
            if (root.has_member ("sidebar")) {
                var sidebar = root.get_object_member ("sidebar");

                if (sidebar.has_member ("insights_card_enabled")) {
                    this.insights_card_enabled = sidebar.get_boolean_member ("insights_card_enabled");
                }
                if (sidebar.has_member ("places_card_enabled")) {
                    this.places_card_enabled = sidebar.get_boolean_member ("places_card_enabled");
                }
                if (sidebar.has_member ("tag_order")) {
                    var arr = sidebar.get_array_member ("tag_order");
                    string[] tmp = {};
                    foreach (var el in arr.get_elements ()) {
                        tmp += el.get_string ();
                    }
                    this.tag_order = tmp;
                }
            }
        }

        private void save () {
            var root_obj = new Json.Object ();
            root_obj.set_int_member ("version", 1);

            // Scheduling object
            var sched_obj = new Json.Object ();
            sched_obj.set_boolean_member ("enabled", this.scheduling_enabled);
            sched_obj.set_string_member ("time", this.scheduling_time);

            var days_array = new Json.Array ();
            foreach (var d in this.scheduling_days) {
                days_array.add_int_element (d);
            }
            sched_obj.set_array_member ("days_of_week", days_array);

            root_obj.set_object_member ("scheduling", sched_obj);

            // Streak object
            var streak_obj = new Json.Object ();
            streak_obj.set_boolean_member ("enabled", this.streak_enabled);
            streak_obj.set_string_member ("time", this.streak_time);
            root_obj.set_object_member ("streak", streak_obj);

            // Sidebar object
            var sidebar_obj = new Json.Object ();
            sidebar_obj.set_boolean_member ("insights_card_enabled", this.insights_card_enabled);
            sidebar_obj.set_boolean_member ("places_card_enabled", this.places_card_enabled);

            var tag_order_array = new Json.Array ();
            foreach (var uuid in this.tag_order) {
                tag_order_array.add_string_element (uuid);
            }
            sidebar_obj.set_array_member ("tag_order", tag_order_array);
            root_obj.set_object_member ("sidebar", sidebar_obj);

            // Write pretty JSON
            var generator = new Json.Generator ();
            generator.set_pretty (true);
            var root_node = new Json.Node (Json.NodeType.OBJECT);
            root_node.set_object (root_obj);
            generator.set_root (root_node);

            try {
                string? data = generator.to_data (null);
                GLib.FileUtils.set_contents (this.settings_path, data);
                changed ();
            } catch (Error e) {
                warning ("Failed to save settings: %s", e.message);
            }
        }

        // ---- Helpers --------------------------------------------------------

        // Return true if both arrays have the same elements in the same order.
        private bool arrays_equal (int[] a, int[] b) {
            if (a.length != b.length)return false;
            for (int i = 0; i < a.length; i++) {
                if (a[i] != b[i])return false;
            }
            return true;
        }

        // Ensure days are unique, within [1..7], and sorted ascending.
        private int[] sanitize_days (int[] days) {
            bool[] seen = new bool[8]; // 0..7; ignore index 0
            int[] out_days = {};
            foreach (var d in days) {
                if (d >= 1 && d <= 7 && !seen[d]) {
                    seen[d] = true;
                }
            }
            for (int d = 1; d <= 7; d++) {
                if (seen[d])out_days += d;
            }
            return out_days;
        }

        // Normalizes a HH:MM 24h time string; returns fallback if invalid.
        private string normalize_time_or_fallback (string time_hhmm, string fallback) {
            int h = 0;
            int m = 0;

            if (parse_hhmm (time_hhmm, out h, out m)) {
                return "%02d:%02d".printf (h, m);
            }
            return fallback;
        }

        private bool parse_hhmm (string s, out int h, out int m) {
            h = 0;
            m = 0;
            if (s == null)return false;
            var trimmed = s.strip ();
            var parts = trimmed.split (":");
            if (parts.length != 2)return false;

            h = int.parse (parts[0]);
            m = int.parse (parts[1]);
            if (h < 0 || h > 23)return false;
            if (m < 0 || m > 59)return false;
            return true;
        }
    }
}
