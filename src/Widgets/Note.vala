/*
* Copyright (C) 2017-2021 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
namespace Notejot {
    public class Log : Object {
        public string title { get; set; }
        public string subtitle { get; set; }
        public string text { get; set; }
        public string color { get; set; }
        public string notebook { get; set; }
    }

    public class Widgets.Note : Hdy.ActionRow {
        public Widgets.TextField textfield;
        public Widgets.FormatBar formatbar;
        public Gtk.Label titlelabel;
        public Gtk.Label subtitlelabel;
        private static int uid_counter;
        public int uid;
        private Gtk.CssProvider css_provider;

        public unowned Log log { get; construct; }
        public unowned MainWindow win { get; construct; }

        public Note (MainWindow win, Log? log) {
            Object (log: log,
                    win: win);
            this.uid = uid_counter++;

            if (log.title == "") {
                set_title (_("New Note ") + (uid + 1).to_string());
            } else {
                set_title (log.title);
            }

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("", Gtk.IconSize.SMALL_TOOLBAR);
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            add_prefix (icon);

            this.show_all ();
            this.get_style_context ().add_class ("notejot-sidebar-box");

            update_theme (log.color);

            textfield = new Widgets.TextField (win);
            var text_scroller = new Gtk.ScrolledWindow (null, null);
            text_scroller.vexpand = true;
            text_scroller.add(textfield);
            textfield.text = log.text;
            textfield.controller = this;
            textfield.update_html_view.begin ();

            titlelabel = new Gtk.Label (log.title);
            subtitlelabel = new Gtk.Label (log.subtitle);
            formatbar = new Widgets.FormatBar ();
            formatbar.controller = textfield;
            formatbar.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            formatbar.notebooklabel.set_label (log.notebook);

            formatbar.notebooklabel.notify["get-text"].connect (() => {
                log.notebook = formatbar.notebooklabel.get_text();
            });

            set_notebook ();

            var note_grid = new Gtk.Grid ();
            note_grid.column_spacing = 12;
            note_grid.attach (text_scroller, 0, 3);
            note_grid.attach (formatbar, 0, 4);
            note_grid.show_all ();

            win.main_stack.add_named (note_grid, "textfield-%d".printf(uid));
            note_grid.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            sync_subtitles ();
            Timeout.add_seconds(1, () => {
                sync_subtitles ();
                return true;
            });

            titlelabel.notify["get-text"].connect (() => {
                set_title (titlelabel.get_text());
                log.title = titlelabel.get_text();
                sync_subtitles ();
            });

            subtitlelabel.notify["get-text"].connect (() => {
                set_subtitle (subtitlelabel.get_text());
                log.subtitle = subtitlelabel.get_text();
                sync_subtitles ();
            });

            win.notebookstore.items_changed.connect (() => {
                win.tm.save_notes.begin (win.notestore);
            });

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                }
            });
        }

        public void destroy_item () {
            this.dispose ();
            css_provider.dispose ();
            win.tm.save_notes.begin (win.notestore);
        }

        public void select_item () {
            if (win.main_stack != null) {
                win.main_stack.set_visible_child_name ("textfield-%d".printf(uid));
            }
        }

        public void set_notebook () {
            if (log.notebook != "") {
                formatbar.notebooklabel.set_label (log.notebook);
                log.notebook = formatbar.notebooklabel.get_text();
            } else {
                formatbar.notebooklabel.set_label (_("No Notebook"));
                log.notebook = formatbar.notebooklabel.get_text();
            }
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                background: mix(%s, @theme_bg_color, 0.5);
                border-radius: 9999px;
                border: 1px solid alpha(@theme_fg_color, 0.25);
            }
            .notejot-action-%d {
                background: mix(%s, @theme_bg_color, 0.9);
            }
            .notejot-stack-%d {
                background: mix(%s, @theme_bg_color, 0.9);
            }
            actionbar.notejot-stack-%d {
                background: mix(%s, @theme_bg_color, 0.9);
                border-top: 1px solid alpha(@theme_fg_color, 0.25);
            }
            .notejot-stack-%d box {
                border: none;
            }
            """)).printf(uid, color, uid, color, uid, color, uid, color, uid);

            try {
                css_provider.load_from_data(style, -1);
            } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
            }

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            log.color = color;
            win.tm.save_notes.begin (win.notestore);
        }

        public void sync_subtitles () {
            try {
                var reg = new Regex("""(?m)^.*, (?<day>\d{2})/(?<month>\d{2}) (?<hour>\d{2})∶(?<minute>\d{2})$""");
                GLib.MatchInfo match;

                if (this != null && subtitlelabel != null) {
                    if (reg.match (subtitlelabel.get_text(), 0, out match)) {
                        var e = new GLib.DateTime.now_local ();
                        var d = new DateTime.local (e.get_year (),
                                                    int.parse(match.fetch_named ("month")),
                                                    int.parse(match.fetch_named ("day")),
                                                    int.parse(match.fetch_named ("hour")),
                                                    int.parse(match.fetch_named ("minute")),
                                                    e.get_second ());
                        subtitlelabel.set_text("%s".printf(Utils.get_relative_datetime(d)));

                        Timeout.add_seconds(1, () => {
                            set_title("%s".printf(get_first_line (log.text)));
                            set_subtitle("%s · %s".printf(Utils.get_relative_datetime_compact(d), get_second_line (log.text)));
                            set_notebook ();
                            return true;
                        });
                    }
                }
                win.tm.save_notes.begin (win.notestore);
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }
        }

        public string get_first_line (string text) {
            string first_line = "";

            try {
                var reg = new Regex("""(?m)(?<first_line>^[^\.\!\?\n\r].+)<br>""");
                var reg2 = new Regex("""(?m)(?<html><([^>]*)>)""");
                var reg3 = new Regex("""(?m)(?<html2></([^>]*)>)""");
                GLib.MatchInfo match;
                GLib.MatchInfo match2;
                GLib.MatchInfo match3;

                if (reg.match (text, 0, out match) && text != null) {
                    if (reg2.match (text, 0, out match2)) {
                        if (reg3.match (text, 0, out match3)) {
                            first_line = match.fetch_named ("first_line")
                                         .replace(match2.fetch_named ("html"),"")
                                         .replace(match3.fetch_named ("html2"),"");
                        }
                    } else {
                        first_line = match.fetch_named ("first_line");
                    }
                } else {
                    first_line = "Empty note";
                }
            } catch (RegexError re) {
                warning ("%s".printf(re.message));
            }
            return first_line;
        }

        public string get_second_line (string text) {
            string second_line = "";

            try {
                var reg = new Regex("""(?m)<br>(?<second_line>.+)$""");
                var reg2 = new Regex("""(?m)(?<html><([A-Za-z][A-Za-z][A-Za-z]*)>)""");
                var reg3 = new Regex("""(?m)(?<html2></([A-Za-z][A-Za-z][A-Za-z]*)>)""");
                GLib.MatchInfo match;
                GLib.MatchInfo match2;
                GLib.MatchInfo match3;

                if (reg.match (text, 0, out match) && text != null) {
                    if (reg2.match (text, 0, out match2)) {
                        if (reg3.match (text, 0, out match3)) {
                            second_line = match.fetch_named ("second_line")
                                         .replace(match2.fetch_named ("html"),"")
                                         .replace(match3.fetch_named ("html2"),"");
                        }
                    } else {
                        second_line = match.fetch_named ("second_line");
                    }
                } else {
                    second_line = "Empty note";
                }
            } catch (RegexError re) {
                warning ("%s".printf(re.message));
            }
            return second_line;
        }

        public void popover_listener (Widgets.NoteMenuPopover? popover) {
            popover.delete_note_button.clicked.connect (() => {
                var tlog = new Log ();
                tlog.title = log.title;
                tlog.subtitle = log.subtitle;
                tlog.text = log.text;
                tlog.color = log.color;
			    win.trashstore.append (tlog);

                win.main_stack.set_visible_child (win.empty_state);
                var row = win.main_stack.get_child_by_name ("textfield-%d".printf(this.uid));
                win.main_stack.remove (row);

                uint pos;
                win.notestore.find (log, out pos);
                win.notestore.remove (pos);
                win.settingmenu.visible = false;
                win.tm.save_notes.begin (win.notestore);
            });

            popover.color_button_red.clicked.connect (() => {
                update_theme("#c01c28");
            });

            popover.color_button_orange.clicked.connect (() => {
                update_theme("#e66100");
            });

            popover.color_button_yellow.clicked.connect (() => {
                update_theme("#f5c211");
            });

            popover.color_button_green.clicked.connect (() => {
                update_theme("#2ec27e");
            });

            popover.color_button_blue.clicked.connect (() => {
                update_theme("#1c71d8");
            });

            popover.color_button_purple.clicked.connect (() => {
                update_theme("#813d9c");
            });

            popover.color_button_brown.clicked.connect (() => {
                update_theme("#865e3c");
            });

            popover.color_button_reset.clicked.connect (() => {
                update_theme("#ffffff");
            });
        }
    }
}
