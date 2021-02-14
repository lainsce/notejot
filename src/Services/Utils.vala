namespace Notejot {
    public class Utils {
        public static bool is_same_day (GLib.DateTime day1, GLib.DateTime day2) {
            return day1.get_day_of_year () == day2.get_day_of_year () && day1.get_year () == day2.get_year ();
        }

        private static bool is_clock_format_12h () {
            var h24_settings = new GLib.Settings ("org.gnome.desktop.interface");
            var format = h24_settings.get_string ("clock-format");
            return (format.contains ("12h"));
        }

        public static string get_default_date_format (bool with_weekday = false, bool with_day = true, bool with_year = false) {
            if (with_weekday == true && with_day == true && with_year == true) {
                /// TRANSLATORS: a GLib.DateTime format showing the weekday, date, and year
                return _("%a, %b %e, %Y");
            } else if (with_weekday == false && with_day == true && with_year == true) {
                /// TRANSLATORS: a GLib.DateTime format showing the date and year
                return _("%b %e %Y");
            } else if (with_weekday == false && with_day == false && with_year == true) {
                /// TRANSLATORS: a GLib.DateTime format showing the year
                return _("%Y");
            } else if (with_weekday == false && with_day == true && with_year == false) {
                /// TRANSLATORS: a GLib.DateTime format showing the date
                return _("%b %e");
            } else if (with_weekday == true && with_day == false && with_year == true) {
                /// TRANSLATORS: a GLib.DateTime format showing the weekday and year.
                return _("%a %Y");
            } else if (with_weekday == true && with_day == false && with_year == false) {
                /// TRANSLATORS: a GLib.DateTime format showing the weekday
                return _("%a");
            } else if (with_weekday == true && with_day == true && with_year == false) {
                /// TRANSLATORS: a GLib.DateTime format showing the weekday and date
                return _("%a, %b %e");
            } else if (with_weekday == false && with_day == false && with_year == false) {
                /// TRANSLATORS: a GLib.DateTime format showing the month.
                return _("%b");
            }

            return "";
        }

        public static string get_default_time_format (bool is_12h = false, bool with_second = false) {
            if (is_12h == true) {
                if (with_second == true) {
                    /// TRANSLATORS: a GLib.DateTime format showing the hour (12h format) with seconds
                    return _("%-l:%M:%S %p");
                } else {
                    /// TRANSLATORS: a GLib.DateTime format showing the hour (12h format)
                    return _("%-l:%M %p");
                }
            } else {
                if (with_second == true) {
                    /// TRANSLATORS: a GLib.DateTime format showing the hour (24h format) with seconds
                    return _("%H:%M:%S");
                } else {
                    /// TRANSLATORS: a GLib.DateTime format showing the hour (24h format)
                    return _("%H:%M");
                }
            }
        }

        public static string get_relative_datetime (GLib.DateTime date_time) {
            var now = new GLib.DateTime.now_local ();
            var diff = now.difference (date_time);

            if (is_same_day (date_time, now)) {
                if (diff > 0) {
                    if (diff < TimeSpan.MINUTE) {
                        return _("Now");
                    } else if (diff < TimeSpan.HOUR) {
                        var minutes = diff / TimeSpan.MINUTE;
                        return ngettext ("%d minute ago", "%d minutes ago", (ulong) (minutes)).printf ((int) (minutes));
                    } else if (diff < 12 * TimeSpan.HOUR) {
                        int rounded = (int) Math.round ((double) diff / TimeSpan.HOUR);
                        return ngettext ("%d hour ago", "%d hours ago", (ulong) rounded).printf (rounded);
                    }
                } else {
                    diff = -1 * diff;
                    if (diff < TimeSpan.HOUR) {
                        var minutes = diff / TimeSpan.MINUTE;
                        return ngettext ("in %d minute", "in %d minutes", (ulong) (minutes)).printf ((int) (minutes));
                    } else if (diff < 12 * TimeSpan.HOUR) {
                        int rounded = (int) Math.round ((double) diff / TimeSpan.HOUR);
                        return ngettext ("in %d hour", "in %d hours", (ulong) rounded).printf (rounded);
                    }
                }

                return date_time.format (get_default_time_format (is_clock_format_12h (), false));
            } else if (is_same_day (date_time.add_days (1), now)) {
                return _("Yesterday");
            } else if (is_same_day (date_time.add_days (-1), now)) {
                return _("Tomorrow");
            } else if (diff < 6 * TimeSpan.DAY && diff > -6 * TimeSpan.DAY) {
                return date_time.format (get_default_date_format (true, false, false));
            } else if (date_time.get_year () == now.get_year ()) {
                return date_time.format (get_default_date_format (false, true, false));
            } else {
                return date_time.format ("%x");
            }
        }
    }
}
