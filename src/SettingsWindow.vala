/*
 * SettingsWindow.vala
 *
 * Settings UI for:
 * - Scheduling: choose time and days of week for weekly write reminders
 * - Streak keeping: choose time for daily streak reminder
 *
 * Relies on SettingsManager for persistence.
 */

namespace Notejot {

    public class SettingsWindow : He.Window {
        private SettingsManager settings;

        // Scheduling controls
        private Gtk.Switch scheduling_switch;
        private Gtk.SpinButton sched_hour_spin;
        private Gtk.SpinButton sched_min_spin;
        private Gtk.ToggleButton[] day_buttons = new Gtk.ToggleButton[7];

        // Streak controls
        private Gtk.Switch streak_switch;
        private Gtk.SpinButton streak_hour_spin;
        private Gtk.SpinButton streak_min_spin;

        public SettingsWindow (Gtk.Window? parent = null) {
            Object ();
            if (parent != null) {
                this.set_transient_for (parent);
            }
            this.set_title (_("Settings"));
            this.add_css_class ("dialog-content");

            this.settings = SettingsManager.get_default ();

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            this.set_child (root);

            // Header
            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            header_box.set_margin_top (12);
            header_box.set_margin_start (12);
            header_box.set_margin_end (12);
            header_box.set_margin_bottom (12);

            var title_label = new Gtk.Label (_("Settings")) { halign = Gtk.Align.START };
            title_label.add_css_class ("title-3");
            header_box.append (title_label);

            header_box.append (new Gtk.Label ("") { hexpand = true }); // spacer

            var close_button = new He.Button ("window-close-symbolic", "");
            close_button.is_disclosure = true;
            close_button.clicked.connect (() => { this.close (); });
            header_box.append (close_button);

            var winhandle = new Gtk.WindowHandle ();
            winhandle.set_child (header_box);
            root.append (winhandle);

            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 18);
            content.set_margin_start (18);
            content.set_margin_end (18);
            content.set_margin_bottom (18);
            root.append (content);

            // Scheduling section
            var scheduling_header = new Gtk.Label (_("Scheduling")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            scheduling_header.add_css_class ("tags-header");
            content.append (scheduling_header);

            var scheduling_card = build_scheduling_card ();
            content.append (scheduling_card);

            // Streak section
            var streak_header = new Gtk.Label (_("Streak keeping")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            streak_header.add_css_class ("tags-header");
            content.append (streak_header);

            var streak_card = build_streak_card ();
            content.append (streak_card);

            // Load values from settings
            load_from_settings ();

            this.present ();
        }

        private Gtk.Widget build_scheduling_card () {
            var card_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            card_box.set_margin_start (12);
            card_box.set_margin_end (12);
            card_box.set_margin_top (12);
            card_box.set_margin_bottom (12);

            // Title + switch
            var row1 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var title = new Gtk.Label (_("Weekly reminder")) {
                halign = Gtk.Align.START,
                hexpand = true,
                xalign = 0
            };
            title.add_css_class ("stat-title");
            row1.append (title);

            this.scheduling_switch = new Gtk.Switch ();
            this.scheduling_switch.halign = Gtk.Align.END;
            this.scheduling_switch.valign = Gtk.Align.CENTER;
            this.scheduling_switch.notify["active"].connect (() => {
                bool enabled = this.scheduling_switch.get_active ();
                this.settings.set_scheduling_enabled (enabled);
                set_scheduling_sensitive (enabled);
            });
            row1.append (this.scheduling_switch);
            card_box.append (row1);

            // Time row
            var row2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var time_lbl = new Gtk.Label (_("Time")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            time_lbl.add_css_class ("stat-title");
            row2.append (time_lbl);

            var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) { hexpand = true };
            time_box.add_css_class ("time-box");

            this.sched_hour_spin = new Gtk.SpinButton.with_range (0, 23, 1);
            this.sched_hour_spin.set_digits (0);
            this.sched_hour_spin.set_wrap (true);
            this.sched_hour_spin.set_width_chars (2);
            this.sched_hour_spin.value_changed.connect (() => on_sched_time_changed ());
            time_box.append (this.sched_hour_spin);

            var colon = new Gtk.Label (":") { valign = Gtk.Align.CENTER };
            time_box.append (colon);

            this.sched_min_spin = new Gtk.SpinButton.with_range (0, 59, 1);
            this.sched_min_spin.set_digits (0);
            this.sched_min_spin.set_wrap (true);
            this.sched_min_spin.set_width_chars (2);
            this.sched_min_spin.value_changed.connect (() => on_sched_time_changed ());
            time_box.append (this.sched_min_spin);

            row2.append (time_box);
            card_box.append (row2);

            // Days of week row
            var row3 = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            var days_lbl = new Gtk.Label (_("Days of the week")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            days_lbl.add_css_class ("stat-title");
            row3.append (days_lbl);

            var days_box = new He.SegmentedButton ();
            string[] names = { _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat"), _("Sun") };
            for (int i = 0; i < 7; i++) {
                var btn = new Gtk.ToggleButton.with_label (names[i]);
                btn.add_css_class ("day-toggle");
                btn.toggled.connect (() => on_day_toggled ());
                days_box.append (btn);
                this.day_buttons[i] = btn;
            }
            row3.append (days_box);
            card_box.append (row3);

            var frame = new Gtk.Frame ("") { child = card_box, hexpand = true };
            frame.label_widget.visible = false;
            frame.add_css_class ("settings-card");
            return frame;
        }

        private Gtk.Widget build_streak_card () {
            var card_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            card_box.set_margin_start (12);
            card_box.set_margin_end (12);
            card_box.set_margin_top (12);
            card_box.set_margin_bottom (12);

            // Title + switch
            var row1 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var title = new Gtk.Label (_("Daily streak reminder")) {
                halign = Gtk.Align.START,
                hexpand = true,
                xalign = 0
            };
            title.add_css_class ("stat-title");
            row1.append (title);

            this.streak_switch = new Gtk.Switch ();
            this.streak_switch.halign = Gtk.Align.END;
            this.streak_switch.valign = Gtk.Align.CENTER;
            this.streak_switch.notify["active"].connect (() => {
                bool enabled = this.streak_switch.get_active ();
                this.settings.set_streak_enabled (enabled);
                set_streak_sensitive (enabled);
            });
            row1.append (this.streak_switch);
            card_box.append (row1);

            // Time row
            var row2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var time_lbl = new Gtk.Label (_("Time")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            time_lbl.add_css_class ("stat-title");
            row2.append (time_lbl);

            var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) { hexpand = true };
            time_box.add_css_class ("time-box");

            this.streak_hour_spin = new Gtk.SpinButton.with_range (0, 23, 1);
            this.streak_hour_spin.set_digits (0);
            this.streak_hour_spin.set_wrap (true);
            this.streak_hour_spin.set_width_chars (2);
            this.streak_hour_spin.value_changed.connect (() => on_streak_time_changed ());
            time_box.append (this.streak_hour_spin);

            var colon = new Gtk.Label (":") { valign = Gtk.Align.CENTER };
            time_box.append (colon);

            this.streak_min_spin = new Gtk.SpinButton.with_range (0, 59, 1);
            this.streak_min_spin.set_digits (0);
            this.streak_min_spin.set_wrap (true);
            this.streak_min_spin.set_width_chars (2);
            this.streak_min_spin.value_changed.connect (() => on_streak_time_changed ());
            time_box.append (this.streak_min_spin);

            row2.append (time_box);
            card_box.append (row2);

            var frame = new Gtk.Frame ("") { child = card_box, hexpand = true };
            frame.label_widget.visible = false;
            frame.add_css_class ("settings-card");
            return frame;
        }

        private void load_from_settings () {
            // Scheduling
            bool sched_enabled = settings.get_scheduling_enabled ();
            this.scheduling_switch.set_active (sched_enabled);
            set_scheduling_sensitive (sched_enabled);

            set_spins_from_time (this.sched_hour_spin, this.sched_min_spin, settings.get_scheduling_time ());

            var days = settings.get_scheduling_days_of_week ();
            for (int i = 0; i < 7; i++) {
                int day_val = i + 1; // 1..7
                bool active = false;
                foreach (var d in days) {
                    if (d == day_val) { active = true; break; }
                }
                this.day_buttons[i].set_active (active);
            }

            // Streak
            bool streak_enabled = settings.get_streak_enabled ();
            this.streak_switch.set_active (streak_enabled);
            set_streak_sensitive (streak_enabled);

            set_spins_from_time (this.streak_hour_spin, this.streak_min_spin, settings.get_streak_time ());
        }

        private void set_scheduling_sensitive (bool enabled) {
            this.sched_hour_spin.set_sensitive (enabled);
            this.sched_min_spin.set_sensitive (enabled);
            for (int i = 0; i < 7; i++) {
                this.day_buttons[i].set_sensitive (enabled);
            }
        }

        private void set_streak_sensitive (bool enabled) {
            this.streak_hour_spin.set_sensitive (enabled);
            this.streak_min_spin.set_sensitive (enabled);
        }

        private void on_sched_time_changed () {
            var t = "%02d:%02d".printf ((int) this.sched_hour_spin.get_value (), (int) this.sched_min_spin.get_value ());
            this.settings.set_scheduling_time (t);
        }

        private void on_streak_time_changed () {
            var t = "%02d:%02d".printf ((int) this.streak_hour_spin.get_value (), (int) this.streak_min_spin.get_value ());
            this.settings.set_streak_time (t);
        }

        private void on_day_toggled () {
            // Build list of active day indices 1..7
            int[] active_days = {};
            for (int i = 0; i < 7; i++) {
                if (this.day_buttons[i].get_active ()) {
                    active_days += (i + 1);
                }
            }
            this.settings.set_scheduling_days_of_week (active_days);
        }

        private void set_spins_from_time (Gtk.SpinButton hour, Gtk.SpinButton min, string hhmm) {
            int h = 0;
            int m = 0;
            try {
                var parts = hhmm.split (":");
                if (parts.length == 2) {
                    h = int.parse (parts[0]);
                    m = int.parse (parts[1]);
                }
            } catch (Error e) {
                // ignore, keep defaults
            }
            hour.set_value (h.clamp (0, 23));
            min.set_value (m.clamp (0, 59));
        }
    }
}
