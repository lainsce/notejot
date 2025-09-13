namespace Notejot {
    public class MonthlyDaysBarChart : Gtk.DrawingArea {

        private int[] month_day_counts = new int[12];
        private int max_value = 0;

        public MonthlyDaysBarChart() {
            this.set_content_width(210); // 12 * (8 bar + ~9 spacing) + left axis space
            this.set_content_height(120);
            this.set_draw_func(on_draw);
        }

        public void set_counts(int[] counts) {
            if (counts.length != 12) {
                return;
            }
            for (int i = 0; i < 12; i++) {
                month_day_counts[i] = counts[i];
            }
            max_value = 0;
            foreach (var v in month_day_counts) {
                if (v > max_value)max_value = v;
            }
            queue_draw();
        }

        private int round_up_five(int v) {
            if (v <= 0)return 5;
            if (v % 5 == 0)return v;
            return v + (5 - v % 5);
        }

        private void on_draw(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            // Layout parameters
            int left_axis_space = 32;
            int bottom_labels_space = 22;
            int top_padding = 6;
            int right_padding = 4;
            int bar_width = 2;
            int available_bar_area_width = width - left_axis_space - right_padding;
            int bar_count = 12;

            // Compute spacing between bars
            // Ensure at least 4px spacing
            double spacing = 0;
            if (bar_count > 1) {
                spacing = (available_bar_area_width - bar_count * bar_width) / (double) (bar_count - 1);
                if (spacing < 4) {
                    spacing = 4;
                }
            }

            int chart_height = height - bottom_labels_space - top_padding;
            if (chart_height < 10)return;

            // Determine maximum (rounded to next multiple of 5)
            int display_max = round_up_five(max_value);
            if (display_max < 5)display_max = 5; // Ensure at least one tick

            // Background (transparent; assume themed)
            // Draw horizontal grid lines for each 5-step (excluding 0)
            cr.set_source_rgba(0, 0, 0, 0.12);
            cr.set_line_width(1);

            // Use Pango for labels
            var pango_ctx = this.create_pango_context();

            // Y ticks and labels
            for (int tick = 0; tick <= display_max; tick += 5) {
                double y = top_padding + chart_height - (tick / (double) display_max) * chart_height;
                cr.move_to(left_axis_space - 4, y + 0.5);
                cr.line_to(width, y + 0.5);
                cr.stroke();

                // Label
                var layout = new Pango.Layout(pango_ctx);
                layout.set_text(@"$(tick)", -1);
                int tw, th;
                layout.get_pixel_size(out tw, out th);
                cr.set_source_rgba(0, 0, 0, 0.32);
                cr.move_to(left_axis_space - 6 - tw, y - th / 2);
                Pango.cairo_show_layout(cr, layout);
            }

            // Bars
            for (int i = 0; i < bar_count; i++) {
                int value = month_day_counts[i];
                double h = (display_max == 0) ? 0 : (value / (double) display_max) * chart_height;
                double x = left_axis_space + i * (bar_width + spacing);
                double y = top_padding + chart_height - h;

                // Bar fill (or 2x2 square if zero)
                cr.set_source_rgba(1, 1, 1, 1); // White

                if (value == 0) {
                    double baseline = top_padding + chart_height;
                    double sq_x = x + (bar_width - 2) / 2.0;
                    cr.rectangle(sq_x, baseline - 2, 2, 2);
                    cr.fill();
                    continue;
                }

                cr.rectangle(x, y, bar_width, h);
                cr.fill();
            }

            // Line between bars and labels
            double divider_y = top_padding + chart_height + 0.5;
            cr.set_source_rgba(0, 0, 0, 0.32);
            cr.move_to(left_axis_space - 4, divider_y);
            cr.line_to(width, divider_y);
            cr.stroke();

            // Month labels (single letter)
            string[] month_initials = { _("J"), _("F"), _("M"), _("A"), _("M"), _("J"), _("J"), _("A"), _("S"), _("O"), _("N"), _("D") };
            for (int i = 0; i < 12; i++) {
                double x = left_axis_space + i * (bar_width + spacing);
                var layout = new Pango.Layout(pango_ctx);
                layout.set_text(month_initials[i], -1);
                int tw, th;
                layout.get_pixel_size(out tw, out th);
                double label_y = divider_y + 2;
                double label_x = x + (bar_width - tw) / 2;
                cr.set_source_rgba(1, 1, 1, 0.44); // White (44% opacity)
                cr.move_to(label_x, label_y);
                Pango.cairo_show_layout(cr, layout);
            }
        }
    }

    public class InsightsView : Gtk.Box {

        private DataManager data_manager;
        private Gtk.Label total_entries_label;
        private Gtk.Label days_journaled_label;
        private Gtk.Label locations_label;
        private Gtk.Label words_label;
        private Gtk.Label current_streak_label;
        private Gtk.Label longest_daily_streak_label;
        private Gtk.Label longest_week_streak_label;
        private Gtk.Grid calendar_grid;
        private Gtk.Label calendar_month_label;
        private DateTime current_date;

        // New chart widget
        private MonthlyDaysBarChart days_chart;

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

            // --- Streaks ---
            var streaks_header = new Gtk.Label(_("Streaks")) {
                halign = Gtk.Align.START,
                xalign = 0,
                margin_start = 18,
                margin_end = 18
            };
            streaks_header.add_css_class("tags-header");
            this.append(streaks_header);

            var streaks_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            streaks_box.margin_start = 18;
            streaks_box.margin_end = 18;
            this.append(streaks_box);

            // Streak cards (init to 0; will be updated in update_view)
            var current_card = create_stat_card("current-streak-card", _("Current Streak"), "0");
            this.current_streak_label = (current_card.get_first_child() as Gtk.Box) ? .get_first_child() as Gtk.Label;
            streaks_box.append(current_card);

            var longest_daily_card = create_stat_card("longest-daily-streak-card", _("Longest Daily Streak"), "0");
            this.longest_daily_streak_label = (longest_daily_card.get_first_child() as Gtk.Box) ? .get_first_child() as Gtk.Label;
            streaks_box.append(longest_daily_card);

            var longest_week_card = create_stat_card("longest-week-streak-card", _("Longest Week Streak"), "0");
            this.longest_week_streak_label = (longest_week_card.get_first_child() as Gtk.Box) ? .get_first_child() as Gtk.Label;
            streaks_box.append(longest_week_card);

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

            // Calculate initial stats
            var all_entries = this.data_manager.get_entries();
            var unique_days = new GenericSet<string> (str_hash, str_equal);
            int total_words = 0;
            foreach (var entry in all_entries) {
                if (!entry.is_deleted) {
                    unique_days.add(entry.date.format("%Y-%m-%d"));
                    total_words += count_words(entry.content);
                }
            }

            // Count unique locations only
            var unique_locations = this.data_manager.get_unique_locations();
            int location_count = (int) unique_locations.length();

            // Days card with bar chart (custom)
            var days_card = create_days_card_with_chart(_("Days Journaled"), unique_days.length.to_string());
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

        private Gtk.Widget create_days_card_with_chart(string title, string initial_value) {
            // Left side labels
            var values_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
            values_box.set_valign(Gtk.Align.START);

            var value_label = new Gtk.Label(initial_value) {
                halign = Gtk.Align.START
            };
            value_label.add_css_class("stat-value");

            var title_label = new Gtk.Label(title) {
                halign = Gtk.Align.START
            };
            title_label.add_css_class("stat-title");

            values_box.append(value_label);
            values_box.append(title_label);

            this.days_journaled_label = value_label;

            // Chart
            this.days_chart = new MonthlyDaysBarChart();
            this.days_chart.set_hexpand(true);
            this.days_chart.set_vexpand(false);

            // Horizontal box inside card
            var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            hbox.append(values_box);
            hbox.append(this.days_chart);

            var frame = new Gtk.Frame("") {
                child = hbox,
                hexpand = true
            };
            frame.label_widget.visible = false;
            frame.add_css_class("stat-card");
            frame.add_css_class("days-journaled-card");
            return frame;
        }

        private Gtk.Widget create_stat_card(string style_class, string? info = null, string initial_value = "0") {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
            box.set_valign(Gtk.Align.START);

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
            frame.label_widget.visible = false;
            frame.add_css_class("stat-card");
            frame.add_css_class(style_class);

            return frame;
        }

        public void update_view() {
            var all_entries = this.data_manager.get_entries();
            this.total_entries_label.set_label(@"$(all_entries.length ().to_string ()) Entries");

            var unique_days = new GenericSet<string> (str_hash, str_equal);
            int total_words = 0;
            foreach (var entry in all_entries) {
                if (!entry.is_deleted) {
                    unique_days.add(entry.date.format("%Y-%m-%d"));
                    total_words += count_words(entry.content);
                }
            }

            // Count unique locations only
            var unique_locations = this.data_manager.get_unique_locations();
            int location_count = (int) unique_locations.length();
            this.days_journaled_label.set_label(@"$(unique_days.length)");
            this.locations_label.set_label(@"$(location_count)");
            this.words_label.set_label(@"$(total_words)");
            // Update streaks
            int current_streak = calc_current_daily_streak_current_month();
            int longest_daily_streak = calc_longest_daily_streak();
            int longest_week_streak = calc_longest_week_streak();
            this.current_streak_label.set_label(@"$(current_streak)");
            this.longest_daily_streak_label.set_label(@"$(longest_daily_streak)");
            this.longest_week_streak_label.set_label(@"$(longest_week_streak)");

            update_days_chart();
            mark_entry_days();
        }

        private void update_days_chart() {
            if (this.days_chart == null)return;

            // counts per month of distinct days journaled (across all years)
            int[] counts = new int[12];
            var seen_dates = new GenericSet<string> (str_hash, str_equal);

            foreach (var entry in this.data_manager.get_entries()) {
                if (entry.is_deleted)continue;
                var date_key = entry.date.format("%Y-%m-%d");
                if (seen_dates.add(date_key)) {
                    int month_index = entry.date.get_month() - 1;
                    if (month_index >= 0 && month_index < 12) {
                        counts[month_index] += 1;
                    }
                }
            }
            this.days_chart.set_counts(counts);
        }

        private int count_words(string? text) {
            if (text == null || text.strip() == "") {
                return 0;
            }
            int count = 0;
            if (text != "") {
                var tokens = text.strip().split_set(" \t\r\n", 0);
                foreach (var tok in tokens) {
                    if (tok != "") {
                        count++;
                    }
                }
            }
            return count;
        }

        // Compute current daily streak up to today within the current month
        private int calc_current_daily_streak_current_month() {
            var today = new DateTime.now_local();
            int year = today.get_year();
            int month = today.get_month();

            int streak = 0;
            var cursor = today;
            while (cursor.get_year() == year && cursor.get_month() == month) {
                if (has_entry_for_date(cursor)) {
                    streak++;
                    cursor = cursor.add_days(-1);
                } else {
                    break;
                }
            }
            return streak;
        }

        // Compute the longest daily streak (consecutive days) within each month across all time
        private int calc_longest_daily_streak() {
            // Map "YYYY-MM" -> set of days that have entries
            var month_days = new GLib.HashTable<string, GLib.HashTable<int, bool>> (str_hash, str_equal);

            foreach (var entry in this.data_manager.get_entries()) {
                if (entry.is_deleted)continue;
                int y = entry.date.get_year();
                int m = entry.date.get_month();
                int d = entry.date.get_day_of_month();
                var key = "%04d-%02d".printf(y, m);

                GLib.HashTable<int, bool>? set = month_days.lookup(key);
                if (set == null) {
                    set = new GLib.HashTable<int, bool> (GLib.direct_hash, GLib.direct_equal);
                    month_days.insert(key, set);
                }
                set.insert(d, true);
            }

            int global_max = 0;
            // Iterate each month and find longest run
            var month_keys = month_days.get_keys();
            foreach (var key in month_keys) {
                var set = month_days.lookup(key);
                if (set == null) {
                    continue;
                }

                // parse year and month
                int y = int.parse(key.substring(0, 4));
                int m = int.parse(key.substring(5, 2));

                var first = new DateTime.local(y, m, 1, 0, 0, 0);
                int days_in_month = first.add_months(1).add_days(-1).get_day_of_month();

                int current = 0;
                int best = 0;
                for (int day = 1; day <= days_in_month; day++) {
                    if (set.lookup(day)) {
                        current++;
                        if (current > best)best = current;
                    } else {
                        current = 0;
                    }
                }
                if (best > global_max)global_max = best;
            }

            return global_max;
        }

        // Helper: get Monday (start of week) for a given date
        private DateTime monday_of_week(DateTime date) {
            // 1 = Monday ... 7 = Sunday
            int dow = date.get_day_of_week();
            int offset = dow - 1;
            return date.add_days(-offset);
        }

        // Compute longest consecutive week streak across all time
        // A "week" counts if there is at least one entry in that Monday-Sunday period
        private int calc_longest_week_streak() {
            var week_has_entry = new GLib.HashTable<string, bool> (str_hash, str_equal);

            DateTime? min_date = null;
            DateTime? max_date = null;

            foreach (var entry in this.data_manager.get_entries()) {
                if (entry.is_deleted)continue;

                var d = entry.date;
                if (min_date == null || d.compare((!) min_date) < 0)min_date = d;
                if (max_date == null || d.compare((!) max_date) > 0)max_date = d;

                var monday = monday_of_week(d);
                var key = monday.format("%Y-%m-%d");
                week_has_entry.insert(key, true);
            }

            if (min_date == null || max_date == null)return 0;

            var start = monday_of_week((!) min_date);
            var end = monday_of_week((!) max_date);

            int longest = 0;
            int current = 0;

            var cursor = start;
            // iterate week by week until we pass end by 7 days
            while (cursor.compare(end) <= 0) {
                var key = cursor.format("%Y-%m-%d");
                if (week_has_entry.lookup(key)) {
                    current++;
                    if (current > longest)longest = current;
                } else {
                    current = 0;
                }
                cursor = cursor.add_days(7);
            }

            return longest;
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
