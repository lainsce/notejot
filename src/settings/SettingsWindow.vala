namespace Notejot {
    public class SettingsWindow : He.Window {
        private SettingsManager settings;
        private DataManager data_manager;

        // Scheduling controls
        private Gtk.Switch scheduling_switch;
        private Gtk.SpinButton sched_hour_spin;
        private Gtk.SpinButton sched_min_spin;
        private Gtk.ToggleButton[] day_buttons = new Gtk.ToggleButton[7];

        // Streak controls
        private Gtk.Switch streak_switch;
        private Gtk.SpinButton streak_hour_spin;
        private Gtk.SpinButton streak_min_spin;

        // Sync controls
        private Gtk.Switch sync_switch;
        private Gtk.Entry sync_folder_entry;
        private He.Button sync_choose_button;
        private He.Button sync_now_button;
        private He.Button sync_pull_button;
        private He.Button cleanup_media_button;

        public SettingsWindow (Gtk.Window? parent = null, DataManager data_manager) {
            Object ();
            if (parent != null) {
                this.parent = parent;
            }
            this.set_title (_("Settings"));
            this.add_css_class ("dialog-content");

            this.settings = SettingsManager.get_default ();
            this.data_manager = data_manager;

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
            scheduling_header.add_css_class ("settings-header");
            content.append (scheduling_header);

            var scheduling_card = build_scheduling_card ();
            content.append (scheduling_card);

            // Streak section
            var streak_header = new Gtk.Label (_("Streak keeping")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            streak_header.add_css_class ("settings-header");
            content.append (streak_header);

            var streak_card = build_streak_card ();
            content.append (streak_card);

            // Sync section
            var sync_header = new Gtk.Label (_("Sync")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            sync_header.add_css_class ("settings-header");
            content.append (sync_header);

            var sync_card = build_sync_card ();
            content.append (sync_card);

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
            title.add_css_class ("settings-title");
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
                xalign = 0,
                valign = Gtk.Align.START
            };
            time_lbl.add_css_class ("settings-title");
            row2.append (time_lbl);

            var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) { hexpand = true, halign = Gtk.Align.END };

            this.sched_hour_spin = new Gtk.SpinButton.with_range (0, 23, 1);
            this.sched_hour_spin.set_digits (0);
            this.sched_hour_spin.orientation = Gtk.Orientation.VERTICAL;
            this.sched_hour_spin.set_wrap (true);
            this.sched_hour_spin.set_width_chars (2);
            this.sched_hour_spin.value_changed.connect (() => on_sched_time_changed ());
            time_box.append (this.sched_hour_spin);

            var colon = new Gtk.Label (":") { valign = Gtk.Align.CENTER };
            time_box.append (colon);

            this.sched_min_spin = new Gtk.SpinButton.with_range (0, 59, 1);
            this.sched_min_spin.set_digits (0);
            this.sched_min_spin.orientation = Gtk.Orientation.VERTICAL;
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
            days_lbl.add_css_class ("settings-title");
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
            title.add_css_class ("settings-title");
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
                xalign = 0,
                valign = Gtk.Align.START
            };
            time_lbl.add_css_class ("settings-title");
            row2.append (time_lbl);

            var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) { hexpand = true, halign = Gtk.Align.END };

            this.streak_hour_spin = new Gtk.SpinButton.with_range (0, 23, 1);
            this.streak_hour_spin.set_digits (0);
            this.streak_hour_spin.orientation = Gtk.Orientation.VERTICAL;
            this.streak_hour_spin.set_wrap (true);
            this.streak_hour_spin.set_width_chars (2);
            this.streak_hour_spin.value_changed.connect (() => on_streak_time_changed ());
            time_box.append (this.streak_hour_spin);

            var colon = new Gtk.Label (":") { valign = Gtk.Align.CENTER };
            time_box.append (colon);

            this.streak_min_spin = new Gtk.SpinButton.with_range (0, 59, 1);
            this.streak_min_spin.set_digits (0);
            this.streak_min_spin.orientation = Gtk.Orientation.VERTICAL;
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

        private Gtk.Widget build_sync_card () {
            var card_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            card_box.set_margin_start (12);
            card_box.set_margin_end (12);
            card_box.set_margin_top (12);
            card_box.set_margin_bottom (12);

            // Title + switch
            var row1 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var title = new Gtk.Label (_("Nextcloud Folder Sync")) {
                halign = Gtk.Align.START,
                hexpand = true,
                xalign = 0
            };
            title.add_css_class ("settings-title");
            row1.append (title);

            this.sync_switch = new Gtk.Switch ();
            this.sync_switch.halign = Gtk.Align.END;
            this.sync_switch.valign = Gtk.Align.CENTER;
            this.sync_switch.notify["active"].connect (() => {
                bool enabled = this.sync_switch.get_active ();
                this.settings.set_sync_enabled (enabled);
                set_sync_sensitive (enabled);
            });
            row1.append (this.sync_switch);
            card_box.append (row1);

            // Folder row
            var row2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var folder_lbl = new Gtk.Label (_("Folder")) {
                halign = Gtk.Align.START,
                xalign = 0,
                valign = Gtk.Align.START
            };
            folder_lbl.add_css_class ("settings-title");
            row2.append (folder_lbl);

            var folder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) { hexpand = true, halign = Gtk.Align.END };

            this.sync_folder_entry = new Gtk.Entry ();
            this.sync_folder_entry.set_editable (false);
            this.sync_folder_entry.set_hexpand (true);
            folder_box.append (this.sync_folder_entry);

            this.sync_choose_button = new He.Button ("", _("Choose…"));
            this.sync_choose_button.is_fill = true;
            this.sync_choose_button.clicked.connect (on_sync_choose_folder);
            folder_box.append (this.sync_choose_button);

            this.sync_now_button = new He.Button ("", _("Sync Now"));
            this.sync_now_button.is_fill = true;
            this.sync_now_button.clicked.connect (() => {
                if (this.data_manager != null) {
                    this.data_manager.sync_push ();
                }
            });
            folder_box.append (this.sync_now_button);

            this.sync_pull_button = new He.Button ("", _("Pull Now"));
            this.sync_pull_button.is_fill = true;
            this.sync_pull_button.clicked.connect (() => {
                if (this.data_manager != null) {
                    this.data_manager.sync_pull ();
                }
            });
            folder_box.append (this.sync_pull_button);

            this.cleanup_media_button = new He.Button ("", _("Cleanup Media"));
            this.cleanup_media_button.is_fill = true;
            this.cleanup_media_button.clicked.connect (() => {
                if (this.data_manager != null) {
                    this.data_manager.cleanup_media ();
                }
            });
            folder_box.append (this.cleanup_media_button);

            row2.append (folder_box);
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

            // Sync
            bool sync_enabled = settings.get_sync_enabled ();
            this.sync_switch.set_active (sync_enabled);
            set_sync_sensitive (sync_enabled);
            this.sync_folder_entry.set_text (settings.get_sync_folder_path ());
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

        private void set_sync_sensitive (bool enabled) {
            // Folder selector is always enabled so users can choose a location to turn on sync
            if (this.sync_folder_entry != null) {
                this.sync_folder_entry.set_sensitive (true);
            }
            if (this.sync_choose_button != null) {
                this.sync_choose_button.set_sensitive (true);
            }
            if (this.sync_now_button != null) {
                this.sync_now_button.set_sensitive (enabled);
            }
            if (this.sync_pull_button != null) {
                this.sync_pull_button.set_sensitive (enabled);
            }
            if (this.cleanup_media_button != null) {
                this.cleanup_media_button.set_sensitive (enabled);
            }
        }

        private void on_sync_choose_folder () {
            // Use Gtk.FileChooserNative exclusively and hold a static reference to prevent GC auto-dismiss
            Gtk.FileChooserNative? native = null;
            if (native != null) {
                native.show ();
                return;
            }

            native = new Gtk.FileChooserNative (_("Select Sync Folder"),
                                                this as Gtk.Window,
                                                Gtk.FileChooserAction.SELECT_FOLDER,
                                                _("Select"),
                                                _("Cancel"));
            native.set_modal (true);

            native.response.connect ((response) => {
                if (response == Gtk.ResponseType.ACCEPT) {
                    var file = native.get_file ();
                    if (file != null) {
                        var p = file.get_path ();
                        if (p != null) {
                            this.sync_folder_entry.set_text (p);
                            this.settings.set_sync_folder_path (p);
                            // Auto-enable sync when a folder is chosen
                            this.settings.set_sync_enabled (true);
                            if (this.sync_switch != null) {
                                this.sync_switch.set_active (true);
                            }
                            set_sync_sensitive (true);
                        }
                    } else {
                        open_manual_path_dialog ();
                    }
                }
                native.destroy ();
                native = null;
            });

            native.show ();
        }

        private void open_manual_path_dialog () {
            var dialog = new He.Window ();
            dialog.set_transient_for (this as Gtk.Window);
            dialog.set_modal (true);
            dialog.add_css_class ("dialog-content");

            var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            header_box.set_margin_top (12);
            header_box.set_margin_start (12);
            header_box.set_margin_end (12);
            header_box.set_margin_bottom (12);

            var title_label = new Gtk.Label (_("Enter Sync Folder Path")) { halign = Gtk.Align.START };
            title_label.add_css_class ("title-3");
            header_box.append (title_label);

            header_box.append (new Gtk.Label ("") { hexpand = true });

            var close_button = new He.Button ("window-close-symbolic", "");
            close_button.is_disclosure = true;
            close_button.clicked.connect (() => { dialog.close (); });
            header_box.append (close_button);

            var winhandle = new Gtk.WindowHandle ();
            winhandle.set_child (header_box);
            container.append (winhandle);

            var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            content_box.set_margin_start (18);
            content_box.set_margin_end (18);
            content_box.set_margin_bottom (6);

            var path_entry = new He.TextField () { placeholder_text = _("e.g. /home/user/Nextcloud"), hexpand = true };
            content_box.append (path_entry);

            container.append (content_box);

            var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            buttons_box.set_margin_start (18);
            buttons_box.set_margin_end (18);
            buttons_box.set_margin_bottom (18);
            buttons_box.set_halign (Gtk.Align.END);

            var cancel_button = new He.Button ("", _("Cancel"));
            cancel_button.is_tint = true;
            cancel_button.clicked.connect (() => { dialog.close (); });
            buttons_box.append (cancel_button);

            var select_button = new He.Button ("", _("Select"));
            select_button.is_fill = true;
            select_button.clicked.connect (() => {
                var p = path_entry.get_internal_entry ().text;
                if (p != null) {
                    // Expand ~/ to absolute
                    if (p.has_prefix ("~/")) {
                        var home = GLib.Environment.get_home_dir ();
                        if (home != null && home.strip () != "") {
                            p = GLib.Path.build_filename (home, p.substring (2));
                        }
                    }
                    if (p.strip () != "") {
                        this.sync_folder_entry.set_text (p);
                        this.settings.set_sync_folder_path (p);
                        this.settings.set_sync_enabled (true);
                        if (this.sync_switch != null) {
                            this.sync_switch.set_active (true);
                        }
                        set_sync_sensitive (true);
                    }
                }
                dialog.close ();
            });
            buttons_box.append (select_button);

            container.append (buttons_box);

            dialog.set_child (container);
            dialog.present ();
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
            var parts = hhmm.split (":");
            if (parts.length == 2) {
                h = int.parse (parts[0]);
                m = int.parse (parts[1]);
            }
            hour.set_value (h.clamp (0, 23));
            min.set_value (m.clamp (0, 59));
        }
    }
}
