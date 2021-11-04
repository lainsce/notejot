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
        public string pinned { get; set; }
    }

    public class Widgets.Note : Adw.ActionRow {
        public Widgets.TextField textfield;
        public static int uid_counter;
        public int uid;
        public Gtk.CssProvider css_provider;
        public Gtk.Label notebooklabel;
        public Gtk.Label subtitlelabel;
        public Gtk.Entry titleentry;
        public Gtk.Image picon;

        public unowned Log log { get; construct; }
        public unowned MainWindow win { get; construct; }

        public Note (MainWindow win, Log? log) {
            Object (log: log,
                    win: win);
            this.uid = uid_counter++;
            this.hexpand = false;
            this.set_title_lines (1);
            this.set_subtitle_lines (1);

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("");
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            // Pinned marker
            picon = new Gtk.Image.from_icon_name ("view-pin-symbolic");
            picon.halign = Gtk.Align.START;
            picon.valign = Gtk.Align.CENTER;

            var titlebox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            titleentry = new Gtk.Entry ();
            titleentry.set_valign (Gtk.Align.CENTER);
            titleentry.set_margin_top (12);
            titleentry.set_margin_start (12);
            titleentry.set_margin_end (12);
            titleentry.set_text (log.title);
            titleentry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY,"document-edit-symbolic");
            titleentry.set_icon_activatable (Gtk.EntryIconPosition.SECONDARY, true);
            titleentry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Set Note Title"));
            titleentry.get_style_context ().add_class ("title-1");

            titleentry.activate.connect (() => {
                sync_log.begin ();
                win.tm.save_notes.begin (win.notestore);
            });
            titleentry.icon_press.connect (() => {
                sync_log.begin ();
                win.tm.save_notes.begin (win.notestore);
            });

            var notebookbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            notebookbox.set_margin_bottom (12);
            notebookbox.set_margin_start (21);
            notebookbox.set_margin_end (21);

            subtitlelabel = new Gtk.Label ("");
            subtitlelabel.set_margin_end (12);

            notebooklabel = new Gtk.Label ("");
            notebooklabel.set_use_markup (true);
            notebooklabel.notify["get-text"].connect (() => {
                log.notebook = notebooklabel.get_text();
                win.tm.save_notebooks.begin (win.notebookstore);
            });

            var notebookicon = new Gtk.Image.from_icon_name ("notebook-symbolic");
            notebookicon.halign = Gtk.Align.START;
            notebookicon.valign = Gtk.Align.CENTER;

            notebookbox.prepend (notebooklabel);
            notebookbox.prepend (notebookicon);
            notebookbox.prepend (subtitlelabel);

            titlebox.prepend (notebookbox);
            titlebox.prepend (titleentry);

            titlebox.get_style_context ().add_class ("nw-titlebox");
            titlebox.get_style_context ().add_class ("content-header");
            titlebox.get_style_context ().add_class ("nw-titlebox-%d".printf(uid));

            textfield = new Widgets.TextField (win);
            var text_scroller = new Gtk.ScrolledWindow ();
            text_scroller.vexpand = true;
            text_scroller.hexpand = true;
            text_scroller.set_child (textfield);
            Gtk.TextIter A, B;
            textfield.get_buffer ().get_bounds (out A, out B);
            textfield.get_buffer ().insert_markup(ref A, log.text, -1);
            textfield.controller = this;
            textfield.set_can_focus(true);
            textfield.get_style_context ().add_class ("notejot-tview-%d".printf(uid));

            var note_grid = new Gtk.Grid ();
            note_grid.attach (titlebox, 0, 2);
            note_grid.attach (text_scroller, 0, 3);
            win.main_stack.add_named (note_grid, "textfield-%d".printf(uid));
            note_grid.get_style_context ().add_class ("content-view");
            note_grid.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            sync_log.begin ();
            update_theme (log.color);
            this.set_title (log.title);
            this.add_prefix (icon);
            this.add_suffix (picon);
            set_pinned (log.pinned);

            win.notebookstore.items_changed.connect (() => {
                win.tm.save_notes.begin (win.notestore);
                win.tm.save_notebooks.begin (win.notebookstore);
            });
        }

        public void destroy_item () {
            this.dispose ();
            css_provider.dispose ();
        }

        public void select_item () {
            if (win.main_stack != null) {
                win.main_stack.set_visible_child_name ("textfield-%d".printf(uid));
                win.format_revealer.set_reveal_child (true);
            }
        }

        public void set_notebook () {
            if (log != null) {
                notebooklabel.set_label (log.notebook);
            } else {
                notebooklabel.set_label ("<i>" + _("No Notebook") + "</i>");
            }
        }

        public void set_pinned (string? pinned) {
            if (log != null) {
                if (pinned == "1") {
                    picon.set_visible (true);
                } else {
                    picon.set_visible (false);
                }
            }
        }

        public void set_subtitle_label () {
            var dt = new GLib.DateTime.now_local ();
            if (log != null) {
                subtitlelabel.set_label (log.subtitle);
            } else {
                subtitlelabel.set_label ("%s".printf (dt.format ("%A, %d/%m %H∶%M")));
            }
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = """
            .notejot-sidebar-dbg-%d {
                background: linear-gradient(mix(%s, @view_bg_color, 0.5),shade(mix(%s, @view_bg_color, 0.4), 0.9));
                border-radius: 9999px;
            }
            .nw-titlebox-%d {
                background: mix(@view_bg_color, %s, 0.1);
            }
            .nw-formatbar-%d {
                background: mix(@view_bg_color, %s, 0.1);
            }
            .notejot-tview-%d text {
                background: mix(@view_bg_color, %s, 0.03);
            }
            """.printf( uid,
                        color,
                        color,
                        uid,
                        color,
                        uid,
                        color,
                        uid,
                        color
            );

            css_provider.load_from_data(style.data);

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            log.color = color;
        }

        public async void sync_log () {
            try {
                new Thread<void>.try ("", () => {
                    try {
                        var reg = new Regex("""(?m)^.*, (?<day>\d{2})/(?<month>\d{2}) (?<hour>\d{2})∶(?<minute>\d{2})$""");
                        GLib.MatchInfo match;

                        if (log != null) {
                            if (reg.match (log.subtitle, 0, out match)) {
                                var e = new GLib.DateTime.now_local ();
                                var d = new DateTime.local (e.get_year (),
                                                            int.parse(match.fetch_named ("month")),
                                                            int.parse(match.fetch_named ("day")),
                                                            int.parse(match.fetch_named ("hour")),
                                                            int.parse(match.fetch_named ("minute")),
                                                            e.get_second ());

                                set_subtitle("%s · %s".printf(Utils.get_relative_datetime_compact(d),
                                                                  get_first_line (log.text).replace("|", "")
                                                                                           .replace("_", "")
                                                                                           .replace("*", "")
                                                                                           .replace("~", "")));
                                set_notebook ();
                                set_subtitle_label ();
                                set_title (titleentry.get_text());
                                set_pinned (log.pinned);
                                win.tm.save_notes.begin (win.notestore);
                            }
                        }

                        sync_log.callback();

                    } catch (GLib.RegexError re) {
                        warning ("%s".printf(re.message));
                    }
                });
                yield;
            } catch (Error re) {
                warning ("%s".printf(re.message));
            }
        }

        public string get_first_line (string text) {
            string first_line = "";

            try {
                var reg = new Regex("""(?m)(?<first_line>.+)""");
                GLib.MatchInfo match;

                if (reg.match (text, 0, out match) && text != null) {
                    first_line = match.fetch_named ("first_line");
                } else {
                    first_line = "Empty note";
                }
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }
            return first_line;
        }
    }
}
