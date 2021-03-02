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
        public Widgets.EditableLabel titlelabel;
        public Gtk.Label subtitlelabel;
        public Gtk.Label notebooklabel;
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

            titlelabel = new Widgets.EditableLabel (win, title);
            titlelabel.get_style_context ().add_class ("notejot-label-%d".printf(uid));
            titlelabel.halign = Gtk.Align.START;
            titlelabel.margin_top = titlelabel.margin_start = 20;
            titlelabel.title.get_style_context ().add_class ("title-1");

            subtitlelabel = new Gtk.Label (log.subtitle);
            subtitlelabel.get_style_context ().add_class ("notejot-label-%d".printf(uid));
            subtitlelabel.get_style_context ().add_class ("dim-label");

            notebooklabel = new Gtk.Label (log.notebook);
            notebooklabel.set_use_markup (true);
            notebooklabel.get_style_context ().add_class ("notejot-label-%d".printf(uid));
            notebooklabel.get_style_context ().add_class ("dim-label");

            var notebookicon = new Gtk.Image.from_icon_name ("notebook-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            notebookicon.valign = Gtk.Align.CENTER;
            notebookicon.get_style_context ().add_class ("dim-label");

            var nb_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            nb_box.halign = Gtk.Align.START;
            nb_box.margin_start = 20;
            nb_box.pack_start (subtitlelabel);
            nb_box.pack_start (notebookicon);
            nb_box.pack_start (notebooklabel);

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            sep.margin_top = 20;

            var formatbar = new Widgets.FormatBar ();
            formatbar.controller = textfield;

            var note_grid = new Gtk.Grid ();
            note_grid.column_spacing = 12;
            note_grid.attach (titlelabel, 0, 0);
            note_grid.attach (nb_box, 0, 1);
            note_grid.attach (sep, 0, 2);
            note_grid.attach (text_scroller, 0, 3);
            note_grid.attach (formatbar, 0, 4);
            note_grid.show_all ();

            win.main_stack.add_named (note_grid, "textfield-%d".printf(uid));
            note_grid.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            titlelabel.changed.connect (() => {
                set_title (titlelabel.text);
                log.title = titlelabel.text;
                win.tm.save_notes.begin (win.notestore);
            });

            sync_subtitles ();
            Timeout.add_seconds(1, () => {
                sync_subtitles ();
                return true;
            });

            subtitlelabel.notify["get-text"].connect (() => {
                set_subtitle (subtitlelabel.get_text());
                log.subtitle = subtitlelabel.get_text();
                sync_subtitles ();
            });

            if (log.notebook != "") {
                notebooklabel.label = log.notebook;
                log.notebook = notebooklabel.get_text();
            } else {
                notebooklabel.label = "<i>" + _("No Notebook") + "</i>";
                log.notebook = notebooklabel.get_text();
            }

            notebooklabel.notify["get-text"].connect (() => {
                log.notebook = notebooklabel.get_text();
            });

            win.notebookstore.items_changed.connect (() => {
                uint i, n = win.notestore.get_n_items ();
                for (i = 0; i < n; i++) {
                    var item = win.notestore.get_item (i);
                    if (((Log)item).notebook != "") {
                        notebooklabel.label = ((Log)item).notebook;
                        ((Log)item).notebook = notebooklabel.get_text();
                    } else {
                        notebooklabel.label = "<i>" + _("No Notebook") + "</i>";
                        ((Log)item).notebook = notebooklabel.get_text();
                    }
                    win.tm.save_notes.begin (win.notestore);
                }
            });

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                icon.get_style_context ().add_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                titlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                subtitlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                note_grid.get_style_context ().add_class ("notejot-stack-dark-%d".printf(uid));
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                icon.get_style_context ().remove_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                titlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                subtitlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                note_grid.get_style_context ().remove_class ("notejot-stack-dark-%d".printf(uid));
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                    icon.get_style_context ().add_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                    titlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                    subtitlelabel.get_style_context ().add_class ("notejot-label-dark-%d".printf(uid));
                    note_grid.get_style_context ().add_class ("notejot-stack-dark-%d".printf(uid));
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                    icon.get_style_context ().remove_class ("notejot-sidebar-dbg-dark-%d".printf(uid));
                    titlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                    subtitlelabel.get_style_context ().remove_class ("notejot-label-dark-%d".printf(uid));
                    note_grid.get_style_context ().remove_class ("notejot-stack-dark-%d".printf(uid));
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

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                border: 1px solid alpha(black, 0.25);
                background: %s;
                border-radius: 50px;
            }
            .notejot-sidebar-dbg-dark-%d {
                border: 1px solid alpha(black, 0.25);
                background: shade(%s, 0.8);
                border-radius: 50px;
            }
            .notejot-label-%d {
                background: mix(%s, @theme_bg_color, 0.8);
            }
            .notejot-label-dark-%d {
                background: mix(%s, @theme_bg_color, 0.8);
            }
            .notejot-stack-%d {
                background: mix(%s, @theme_bg_color, 0.8);
            }
            .notejot-stack-dark-%d {
                background: mix(%s, @theme_bg_color, 0.8);
            }
            """)).printf(uid, color, uid, color, uid, color, uid, color, uid, color, uid, color);

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
                            set_subtitle ("%s · %s".printf(Utils.get_relative_datetime_compact(d), get_first_line (log.text)));
                            notebooklabel.label = log.notebook;
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
                var reg = new Regex("""(?m)^(?<first_line>.+)$""");
                var reg2 = new Regex("""(?m)(?<html><([A-Za-z][A-Za-z0-9]*)>)""");
                var reg3 = new Regex("""(?m)(?<html2></([A-Za-z][A-Za-z0-9]*)>)""");
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
                    first_line = "Empty note.";
                }
            } catch (RegexError re) {
                warning ("%s".printf(re.message));
            }
            return first_line;
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
                update_theme("#f66151");
            });

            popover.color_button_orange.clicked.connect (() => {
                update_theme("#ffbe6f");
            });

            popover.color_button_yellow.clicked.connect (() => {
                update_theme("#f9f06b");
            });

            popover.color_button_green.clicked.connect (() => {
                update_theme("#8ff0a4");
            });

            popover.color_button_blue.clicked.connect (() => {
                update_theme("#99c1f1");
            });

            popover.color_button_purple.clicked.connect (() => {
                update_theme("#dc8add");
            });

            popover.color_button_brown.clicked.connect (() => {
                update_theme("#cdab8f");
            });

            popover.color_button_reset.clicked.connect (() => {
                update_theme("#ffffff");
            });
        }
    }
}
