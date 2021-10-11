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
    public class PinnedLog : Object {
        public string title { get; set; }
        public string subtitle { get; set; }
        public string text { get; set; }
        public string color { get; set; }
        public string notebook { get; set; }
        public bool pinned { get; set; }
    }

    public class Widgets.PinnedNote : Adw.ActionRow {
        public Widgets.TextField textfield;
        public Widgets.FormatBar formatbar;
        private static int puid_counter;
        public int puid;
        private Gtk.CssProvider css_provider;
        private Gtk.Label notebooklabel;

        public unowned PinnedLog plog { get; construct; }
        public unowned MainWindow win { get; construct; }

        public PinnedNote (MainWindow win, PinnedLog? plog) {
            Object (plog: plog,
                    win: win);
            this.puid = puid_counter++;
            this.hexpand = false;
            this.set_title_lines (1);
            this.set_subtitle_lines (1);

            win.settingmenu.popover = null;
            win.settingmenu.popover = win.sm.pnmpopover;

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("");
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-pin-%d".printf(puid));

            var titlebox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            var titleentry = new Gtk.Entry ();
            titleentry.set_valign (Gtk.Align.CENTER);
            titleentry.set_margin_top (12);
            titleentry.set_margin_bottom (6);
            titleentry.set_margin_start (30);
            titleentry.set_margin_end (30);
            titleentry.set_text (plog.title);
            titleentry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY,"document-edit-symbolic");
            titleentry.set_icon_activatable (Gtk.EntryIconPosition.SECONDARY, true);
            titleentry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Set Note Title"));
            titleentry.get_style_context ().add_class ("title-1");

            titleentry.activate.connect (() => {
                plog.title = titleentry.get_text ();
                win.tm.save_pinned_notes.begin (win.pinotestore);
            });
            titleentry.icon_press.connect (() => {
                plog.title = titleentry.get_text ();
                win.tm.save_pinned_notes.begin (win.pinotestore);
            });
            Timeout.add(50, () => {
                set_title (titleentry.get_text ());
                return true;
            });

            var notebookbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            notebookbox.set_margin_bottom (6);
            notebookbox.set_margin_start (30);
            notebookbox.set_margin_end (30);

            var subtitlelabel = new Gtk.Label (plog.subtitle);
            subtitlelabel.set_margin_end (12);
            subtitlelabel.get_style_context ().add_class ("dim-label");

            notebooklabel = new Gtk.Label ("");
            notebooklabel.set_use_markup (true);
            notebooklabel.get_style_context ().add_class ("dim-label");
            notebooklabel.notify["get-text"].connect (() => {
                plog.notebook = notebooklabel.get_text();
                win.tm.save_notebooks.begin (win.notebookstore);
            });

            var notebookicon = new Gtk.Image.from_icon_name ("notebook-symbolic");
            notebookicon.halign = Gtk.Align.START;
            notebookicon.valign = Gtk.Align.CENTER;
            notebookicon.get_style_context ().add_class ("dim-label");

            notebookbox.prepend (notebooklabel);
            notebookbox.prepend (notebookicon);
            notebookbox.prepend (subtitlelabel);

            titlebox.prepend (notebookbox);
            titlebox.prepend (titleentry);

            titlebox.get_style_context ().add_class ("nw-titlebox");
            titlebox.get_style_context ().add_class ("nw-titlebox-pin-%d".printf(puid));

            textfield = new Widgets.TextField (win);
            var text_scroller = new Gtk.ScrolledWindow ();
            text_scroller.vexpand = true;
            text_scroller.hexpand = true;
            text_scroller.set_child (textfield);
            Gtk.TextIter A, B;
            textfield.get_buffer ().get_bounds (out A, out B);
            textfield.get_buffer ().insert_markup(ref A, plog.text, -1);
            textfield.pcontroller = this;
            textfield.get_style_context ().add_class ("notejot-tview-pin-%d".printf(puid));

            formatbar = new Widgets.FormatBar ();
            formatbar.controller = textfield;

            var note_grid = new Gtk.Grid ();
            note_grid.attach (titlebox, 0, 2);
            note_grid.attach (text_scroller, 0, 3);
            note_grid.attach (formatbar, 0, 4);
            win.main_stack.add_named (note_grid, "textfield-pin-%d".printf(puid));
            note_grid.get_style_context ().add_class ("notejot-stack-pin-%d".printf(puid));

            win.pinlistview.select_row (this);

            sync_subtitles.begin ();
            update_theme (plog.color);
            this.set_title (plog.title);
            this.get_style_context ().add_class ("notejot-sidebar-box");
            this.add_prefix (icon);

            win.notebookstore.items_changed.connect (() => {
                win.tm.save_pinned_notes.begin (win.pinotestore);
            });
        }

        public void destroy_item () {
            this.dispose ();
            css_provider.dispose ();
            win.tm.save_pinned_notes.begin (win.pinotestore);
        }

        public void select_item () {
            if (win.main_stack != null) {
                win.main_stack.set_visible_child_name ("textfield-pin-%d".printf(puid));
            }
        }

        public void set_notebook () {
            if (plog != null) {
                notebooklabel.set_label (plog.notebook);
            } else {
                notebooklabel.set_label ("<i>" + _("No Notebook") + "</i>");
            }
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = """
            .notejot-sidebar-dbg-pin-%d {
                background: mix(%s, @theme_bg_color, 0.5);
                border: 1px solid @borders;
                border-radius: 9999px;
            }
            .notejot-action-pin-%d {
                background: mix(@theme_bg_color, %s, 0.06);
                border-bottom: 1px solid @borders;
            }
            .nw-titlebox-pin-%d {
                background: mix(@theme_base_color, %s, 0.06);
            }
            .notejot-stack-pin-%d .notejot-bar {
                background: mix(@theme_bg_color, %s, 0.06);
            }
            .notejot-tview-pin-%d text {
                background: mix(@theme_base_color, %s, 0.06);
            }
            """.printf(  puid,
                         color,
                         puid,
                         color,
                         puid,
                         color,
                         puid,
                         color,
                         puid,
                         color
            );

            css_provider.load_from_data(style.data);

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            plog.color = color;
            win.tm.save_pinned_notes.begin (win.pinotestore);
        }

        public async void sync_subtitles () {
            try {
                var reg = new Regex("""(?m)^.*, (?<day>\d{2})/(?<month>\d{2}) (?<hour>\d{2})∶(?<minute>\d{2})$""");
                GLib.MatchInfo match;

                if (plog != null) {
                    if (reg.match (plog.subtitle, 0, out match)) {
                        var e = new GLib.DateTime.now_local ();
                        var d = new DateTime.local (e.get_year (),
                                                    int.parse(match.fetch_named ("month")),
                                                    int.parse(match.fetch_named ("day")),
                                                    int.parse(match.fetch_named ("hour")),
                                                    int.parse(match.fetch_named ("minute")),
                                                    e.get_second ());

                        Timeout.add(50, () => {
                            set_subtitle("%s · %s".printf(Utils.get_relative_datetime_compact(d),
                                                          get_first_line (plog.text).replace("|", "")
                                                                                   .replace("_", "")
                                                                                   .replace("*", "")
                                                                                   .replace("~", "")));
                            set_notebook ();
                            return true;
                        });
                    }
                }
                win.tm.save_pinned_notes.begin (win.pinotestore);
            } catch (GLib.RegexError re) {
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
