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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/trashrowcontent.ui")]
public class Notejot.TrashRowContent : He.Bin {
    [GtkChild]
    private unowned Gtk.Image pin;
    [GtkChild]
    private unowned Gtk.Box box;
    [GtkChild]
    unowned He.ContentBlockImage image;

    private Binding? pinned_binding;
    private Binding? color_binding;
    private Binding? pix_binding;

    private Gtk.CssProvider provider = new Gtk.CssProvider ();

    private string? _color;
    public string? color {
        get { return _color; }
        set {
            if (value == _color)
                return;

            _color = value;

            if (_color == "") {
                provider.load_from_data ((uint8[]) "@define-color note_color @outline;");
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow>
                     (this)).tview_model.update_trash_color (_trash, _color);
                box.get_style_context ().add_provider (provider, 1);
            } else if (_color == "red") {
                provider.load_from_data ((uint8[]) "@define-color note_color @meson_red;");
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow>
                     (this)).tview_model.update_trash_color (_trash, _color);
                box.get_style_context ().add_provider (provider, 1);
            } else if (_color == "yellow") {
                provider.load_from_data ((uint8[]) "@define-color note_color @electron_yellow;");
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow>
                     (this)).tview_model.update_trash_color (_trash, _color);
                box.get_style_context ().add_provider (provider, 1);
            } else if (_color == "green") {
                provider.load_from_data ((uint8[]) "@define-color note_color @muon_green;");
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow>
                     (this)).tview_model.update_trash_color (_trash, _color);
                box.get_style_context ().add_provider (provider, 1);
            } else if (_color == "blue") {
                provider.load_from_data ((uint8[]) "@define-color note_color @proton_blue;");
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow>
                     (this)).tview_model.update_trash_color (_trash, _color);
                box.get_style_context ().add_provider (provider, 1);
            } else if (_color == "purple") {
                provider.load_from_data ((uint8[]) "@define-color note_color @tau_purple;");
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow>
                     (this)).tview_model.update_trash_color (_trash, _color);
                box.get_style_context ().add_provider (provider, 1);
            }
        }
    }

    private Trash? _trash;
    public Trash? trash {
        get { return _trash; }
        set {
            if (value == _trash)
                return;

            pinned_binding?.unbind ();

            color_binding?.unbind ();

            pix_binding?.unbind ();

            _trash = value;

            pinned_binding = _trash ? .bind_property (
                                                      "pinned", pin, "visible", SYNC_CREATE | BIDIRECTIONAL);
            color_binding = _trash ? .bind_property (
                                                     "color", this, "color", SYNC_CREATE | BIDIRECTIONAL);
            pix_binding = _trash ? .bind_property (
                                                   "picture", image, "file", SYNC_CREATE | BIDIRECTIONAL);

            if (_trash != null) {
                if (_trash.picture != "") {
                    image.visible = true;
                } else {
                    image.visible = false;
                }
            }

            image.notify["file"].connect (() => {
                if (image.file != "") {
                    image.visible = true;
                } else {
                    image.visible = false;
                }
            });
        }
    }

    public TrashRowContent (Trash trash) {
        Object (
                trash : trash
        );
    }

    construct {
        box.add_css_class ("notejot-sidebar-box");
        box.get_style_context ().add_provider (provider, 1);
    }

    [GtkCallback]
    string get_text_line () {
        var res = sync_text (trash.text);
        return res;
    }

    [GtkCallback]
    string get_subtitle_line () {
        var res = sync_subtitles (trash.subtitle);
        return res;
    }

    public string sync_subtitles (string subtitle) {
        string res = "";
        try {
            var reg = new Regex ("""(?m)^.*, (?<day>\d{2})/(?<month>\d{2}) (?<hour>\d{2})∶(?<minute>\d{2})$""");
            GLib.MatchInfo match;

            if (log != null) {
                if (reg.match (subtitle, 0, out match)) {
                    var e = new GLib.DateTime.now_local ();
                    var d = new DateTime.local (e.get_year (),
                                                int.parse (match.fetch_named ("month")),
                                                int.parse (match.fetch_named ("day")),
                                                int.parse (match.fetch_named ("hour")),
                                                int.parse (match.fetch_named ("minute")),
                                                e.get_second ());

                    res = "%s".printf (TimeUtils.get_relative_datetime_compact (d));
                }
            }
        } catch (GLib.RegexError re) {
            warning ("%s".printf (re.message));
        }

        return res;
    }

    public string sync_text (string text) {
        string res = "";
        try {
            var reg = new Regex ("""(?m)^(?<s>.*\n*.*)\n*""");
            GLib.MatchInfo match;

            if (log != null) {
                if (reg.match (text, 0, out match)) {
                    res = "%s".printf (match.fetch_named ("s"));
                }
            }
        } catch (GLib.RegexError re) {
            warning ("%s".printf (re.message));
        }

        return res;
    }
}
