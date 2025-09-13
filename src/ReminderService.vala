/*
 * ReminderService.vala
 *
 * Periodically checks user preferences and sends reminders:
 * - Scheduling: on selected weekdays at a configured time
 * - Streak keeping: daily at a configured time
 *
 * Each notification includes a "New Entry" action (app.new-entry) to bring the
 * app to the foreground. The action is registered here and can be extended to
 * open the editor directly once a public method is exposed on the main window.
 */

namespace Notejot {

    public class ReminderService : Object {
        private uint timer_id = 0;
        private SettingsManager settings;

        // Prevent duplicate notifications within the same day
        private string? last_streak_notified_date = null; // YYYY-MM-DD
        private string? last_sched_notified_date = null; // YYYY-MM-DD

        public ReminderService () {
            this.settings = SettingsManager.get_default ();
            // If settings change, we keep going; no timer restart needed.
            this.settings.changed.connect (() => {
                // If user changed times/days, we allow a new notification when
                // the date changes. No immediate action required here.
            });
        }

        public void start () {
            if (this.timer_id != 0)return;

            // Register the application action used by our notifications.
            ensure_new_entry_action_registered ();

            // Check every 30s to avoid missing the exact minute due to drift.
            this.timer_id = GLib.Timeout.add_seconds (30, () => {
                this.tick ();
                return true;
            });
        }

        public void stop () {
            if (this.timer_id != 0) {
                GLib.Source.remove (this.timer_id);
                this.timer_id = 0;
            }
        }

        private void tick () {
            check_streak_reminder ();
            check_scheduling_reminder ();
        }

        // ---------- Streak reminder (daily) ----------------------------------

        private void check_streak_reminder () {
            if (!this.settings.get_streak_enabled ())return;

            int h, m;
            if (!parse_hhmm (this.settings.get_streak_time (), out h, out m))return;

            var now = new GLib.DateTime.now_local ();
            var today_key = now.format ("%Y-%m-%d");

            // Only once per day
            if (this.last_streak_notified_date != null && this.last_streak_notified_date == today_key) {
                return;
            }

            if (matches_time (now, h, m)) {
                send_notification (
                                   "streak-reminder",
                                   _("Keep your streak going"),
                                   _("It’s time to write today. Tap to add a new entry.")
                );
                this.last_streak_notified_date = today_key;
            }
        }

        // ---------- Scheduling reminder (weekly) -----------------------------

        private void check_scheduling_reminder () {
            if (!this.settings.get_scheduling_enabled ())return;

            int h, m;
            if (!parse_hhmm (this.settings.get_scheduling_time (), out h, out m))return;

            var days = this.settings.get_scheduling_days_of_week ();
            if (days.length == 0)return;

            var now = new GLib.DateTime.now_local ();
            var today_key = now.format ("%Y-%m-%d");

            // Only once per day
            if (this.last_sched_notified_date != null && this.last_sched_notified_date == today_key) {
                return;
            }

            int dow = now.get_day_of_week (); // 1=Mon .. 7=Sun
            if (!day_list_contains (days, dow))return;

            if (matches_time (now, h, m)) {
                send_notification (
                                   "schedule-reminder",
                                   _("Time to write"),
                                   _("Your scheduled reminder is here. Tap to add a new entry.")
                );
                this.last_sched_notified_date = today_key;
            }
        }

        // ---------- Helpers --------------------------------------------------

        private bool parse_hhmm (string s, out int h, out int m) {
            h = 0; m = 0;
            if (s == null)return false;
            var parts = s.strip ().split (":");
            if (parts.length != 2)return false;
            h = int.parse (parts[0]);
            m = int.parse (parts[1]);
            if (h < 0 || h > 23)return false;
            if (m < 0 || m > 59)return false;
            return true;
        }

        private bool matches_time (GLib.DateTime now, int hour, int minute) {
            return now.get_hour () == hour && now.get_minute () == minute;
        }

        private bool day_list_contains (int[] days, int value) {
            foreach (var d in days) {
                if (d == value)return true;
            }
            return false;
        }

        private void send_notification (string id, string title, string body) {
            var app = Application.get_default ();
            if (app == null)return;

            // GLib.Notification a.k.a. GNotification
            var n = new Notification (title);
            n.set_body (body);
            n.set_default_action ("app.new-entry"); // Default click -> bring app forward (and new entry if wired)
            n.add_button (_("New Entry"), "app.new-entry");

            // Use a symbolic icon if available
            var icon = new ThemedIcon ("appointment-new-symbolic");
            n.set_icon (icon);

            app.send_notification (id, n);
        }

        private void ensure_new_entry_action_registered () {
            var app = Application.get_default ();
            if (app == null)return;

            if (app.lookup_action ("new-entry") != null)return;

            var action = new SimpleAction ("new-entry", null);
            action.activate.connect ((variant) => {
                // Bring the app to foreground
                app.activate ();

                // Try to present the existing main window
                var gapp = app as Gtk.Application;
                if (gapp != null) {
                    var win = gapp.get_active_window ();
                    if (win != null) {
                        win.present ();
                    }
                }

                var main = gapp.get_active_window () as Notejot.Window;
                if (main != null) {
                    main.open_new_entry ();
                }
            });

            app.add_action (action);
        }
    }
}
