namespace Notejot {
    public class InsightsView : Gtk.Box {

        private DataManager data_manager;
        private Gtk.Label total_entries_label;
        private Gtk.Label days_journaled_label;
        private Gtk.Label locations_label;
        private Gtk.Label words_label;
        private Gtk.Grid calendar_grid;
        private Gtk.Label calendar_month_label;
        private DateTime current_date;

        public InsightsView(DataManager manager) {
            Object(
                   orientation: Gtk.Orientation.VERTICAL,
                   spacing: 0
            );
            this.add_css_class("insights-view");

            this.data_manager = manager;
            this.current_date = new DateTime.now_local();

            var appbar = new He.AppBar();
            appbar.show_left_title_buttons = false;
            this.append(appbar);

            var header = new Gtk.Label(_("Insights")) {
                halign = Gtk.Align.START,
                xalign = 0
            };
            header.add_css_class("header");
            this.append(header);

            this.total_entries_label = new Gtk.Label("0 Entries") {
                halign = Gtk.Align.START,
                xalign = 0
            };
            this.total_entries_label.add_css_class("date-label");
            this.append(this.total_entries_label);

            // --- Stats Cards ---
            var stats_header = new Gtk.Label(_("Stats")) {
                halign = Gtk.Align.START,
                xalign = 0,
                margin_start = 18,
                margin_end = 18
            };
            stats_header.add_css_class("tags-header");
            this.append(stats_header);

            var stats_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            stats_box.margin_start = 18;
            stats_box.margin_end = 18;
            this.append(stats_box);

            // Calculate initial stats to pass to cards
            var all_entries = this.data_manager.get_entries();
            var unique_days = new GenericSet<string> (str_hash, str_equal);
            int location_count = 0;
            int total_words = 0;
            foreach (var entry in all_entries) {
                if (!entry.is_deleted) {
                    unique_days.add(entry.date.format("%Y-%m-%d"));
                    if (entry.location_address != null && entry.location_address != "" &&
                        entry.latitude != 0 && entry.longitude != 0) {
                        location_count++;
                    }
                    total_words += count_words(entry.content);
                }
            }

            var days_card = create_stat_card("days-journaled-card", _("Days Journaled"), unique_days.length.to_string());
            this.days_journaled_label = (days_card.get_first_child() as Gtk.Box) ? .get_first_child() as Gtk.Label;
            stats_box.append(days_card);

            var locations_card = create_stat_card("locations-card", _("Locations"), location_count.to_string());
            this.locations_label = (locations_card.get_first_child() as Gtk.Box) ? .get_first_child() as Gtk.Label;
            stats_box.append(locations_card);

            var words_card = create_stat_card("words-card", _("Total Words"), total_words.to_string());
            this.words_label = (words_card.get_first_child() as Gtk.Box) ? .get_first_child() as Gtk.Label;
            stats_box.append(words_card);

            // --- Calendar ---
            var calendar_header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            calendar_header_box.set_margin_top(12);
            calendar_header_box.set_margin_bottom(12);
            calendar_header_box.set_margin_start(18);
            calendar_header_box.set_margin_end(18);
            this.append(calendar_header_box);

            this.calendar_month_label = new Gtk.Label("") {
                halign = Gtk.Align.START,
                hexpand = true
            };
            this.calendar_month_label.add_css_class("calendar-month-label");
            calendar_header_box.append(this.calendar_month_label);

            var prev_button = new He.Button("go-previous-symbolic", "");
            prev_button.is_disclosure = true;
            prev_button.clicked.connect(on_prev_month);
            calendar_header_box.append(prev_button);

            var next_button = new He.Button("go-next-symbolic", "");
            next_button.is_disclosure = true;
            next_button.clicked.connect(on_next_month);
            calendar_header_box.append(next_button);

            this.calendar_grid = new Gtk.Grid();
            this.calendar_grid.set_margin_start(18);
            this.calendar_grid.set_margin_end(18);
            this.calendar_grid.set_margin_bottom(18);
            this.calendar_grid.set_vexpand(true);
            this.calendar_grid.row_homogeneous = true;
            this.calendar_grid.column_homogeneous = true;
            this.calendar_grid.add_css_class("custom-calendar");
            this.append(this.calendar_grid);

            update_view();
            update_calendar_header();
            build_calendar();
        }

        private Gtk.Widget create_stat_card(string style_class, string? info = null, string initial_value = "0") {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
            box.set_valign(Gtk.Align.CENTER);

            var value_label = new Gtk.Label(initial_value) {
                halign = Gtk.Align.START
            };
            value_label.add_css_class("stat-value");
            box.append(value_label);

            var title_label = new Gtk.Label(info) {
                halign = Gtk.Align.START
            };
            title_label.add_css_class("stat-title");
            box.append(title_label);

            var frame = new Gtk.Frame("") {
                child = box,
                hexpand = true
            };
            frame.add_css_class("stat-card");
            frame.add_css_class(style_class);

            return frame;
        }

        public void update_view() {
            var all_entries = this.data_manager.get_entries();
            this.total_entries_label.set_label(@"$(all_entries.length ().to_string ()) Entries");

            var unique_days = new GenericSet<string> (str_hash, str_equal);
            int location_count = 0;
            int total_words = 0;
            foreach (var entry in all_entries) {
                if (!entry.is_deleted) {
                    unique_days.add(entry.date.format("%Y-%m-%d"));
                    if (entry.latitude != 0 && entry.longitude != 0) {
                        location_count++;
                    }
                    total_words += count_words(entry.content);
                }
            }
            this.days_journaled_label.set_label(@"$(unique_days.length)");
            this.locations_label.set_label(@"$(location_count)");
            this.words_label.set_label(@"$(total_words)");

            mark_entry_days();
        }

        private int count_words(string? text) {
            if (text == null || text.strip() == "") {
                return 0;
            }
            int count = 0;
            try {
                var regex = new GLib.Regex("\\S+");
                GLib.MatchInfo match_info;
                if (regex.match((string) text, 0, out match_info)) {
                    do {
                        count++;
                    } while (match_info.next());
                }
            } catch (Error e) {
                foreach (var part in text.strip().split(" ")) {
                    if (part != "")count++;
                }
            }
            return count;
        }

        private void build_calendar() {
            // Clear existing calendar
            var child = this.calendar_grid.get_first_child();
            while (child != null) {
                var next = child.get_next_sibling();
                this.calendar_grid.remove(child);
                child = next;
            }

            // Add day headers
            string[] day_names = { _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat"), _("Sun") };
            for (int i = 0; i < 7; i++) {
                var label = new Gtk.Label(day_names[i]);
                label.add_css_class("calendar-day-header");
                this.calendar_grid.attach(label, i, 0, 1, 1);
            }

            // Calculate first day of month and number of days
            var first_of_month = new DateTime.local(
                                                    this.current_date.get_year(),
                                                    this.current_date.get_month(),
                                                    1, 0, 0, 0
            );

            int first_weekday = first_of_month.get_day_of_week(); // 1=Monday, 7=Sunday
            int days_in_month = first_of_month.add_months(1).add_days(-1).get_day_of_month();

            // Adjust first_weekday to match our grid (0=Monday, 6=Sunday)
            first_weekday = first_weekday - 1;

            // Get today's date for comparison
            var today = new DateTime.now_local();

            // Add day buttons
            for (int day = 1; day <= days_in_month; day++) {
                int row = 1 + (first_weekday + day - 1) / 7;
                int col = (first_weekday + day - 1) % 7;

                var button = new Gtk.Button.with_label(day.to_string());
                button.set_valign(Gtk.Align.CENTER);
                button.set_halign(Gtk.Align.CENTER);
                button.add_css_class("calendar-day-button");

                // Check if this day has entries
                var day_date = new DateTime.local(
                                                  this.current_date.get_year(),
                                                  this.current_date.get_month(),
                                                  day, 0, 0, 0
                );

                if (has_entry_for_date(day_date)) {
                    button.add_css_class("has-entry");
                }

                // Mark today with the "today" CSS class
                if (day_date.get_year() == today.get_year() &&
                    day_date.get_month() == today.get_month() &&
                    day_date.get_day_of_month() == today.get_day_of_month()) {
                    button.add_css_class("today");
                }

                this.calendar_grid.attach(button, col, row, 1, 1);
            }
        }

        private bool has_entry_for_date(DateTime date) {
            foreach (var entry in this.data_manager.get_entries()) {
                if (!entry.is_deleted &&
                    entry.date.get_year() == date.get_year() &&
                    entry.date.get_month() == date.get_month() &&
                    entry.date.get_day_of_month() == date.get_day_of_month()) {
                    return true;
                }
            }
            return false;
        }

        private void mark_entry_days() {
            build_calendar();
        }

        private void update_calendar_header() {
            this.calendar_month_label.set_label(this.current_date.format("%B %Y"));
            mark_entry_days();
        }

        private void on_prev_month() {
            this.current_date = this.current_date.add_months(-1);
            update_calendar_header();
        }

        private void on_next_month() {
            this.current_date = this.current_date.add_months(1);
            update_calendar_header();
        }
    }
}
