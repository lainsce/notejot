/*
* Copyright (C) 2017-2022 Lains
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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notegridrowcontent.ui")]
public class Notejot.NoteGridRowContent : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image pin;
    [GtkChild]
    unowned Gtk.Box row_box;

    Binding? pinned_binding;
    private Gtk.CssProvider provider = new Gtk.CssProvider();

    string? _color;
    public string? color {
        get { return _color; }
        set {
            if (value == _color)
                return;

            _color = value;

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_note.color));
            ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).view_model.update_note_color (_note, _color);
        }
    }

    Note? _note;
    public Note? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            pinned_binding?.unbind ();

            _note = value;

            pinned_binding = _note?.bind_property (
                "pinned", pin, "visible", SYNC_CREATE|BIDIRECTIONAL);
        }
    }

    public NoteGridRowContent (Note note) {
        Object(
            note: note
        );
    }

    construct {
        row_box.get_style_context().add_provider(provider, 1);
    }

    [GtkCallback]
    string get_text_line () {
        var res = sync_texts (note.text);
        return res;
    }

    public string sync_texts (string text) {
        string res = "";
        try {
            var reg = new Regex("""(?m)(?<sentence>[^.!?\s][^.!?]*(?:[.!?](?!['"]?\s|$)[^.!?]*)*[.!?]?['"]?(?=\s|$))$""");
            GLib.MatchInfo match;

            if (log != null) {
                if (reg.match (text, 0, out match)) {
                    res = "%s".printf(match.fetch_named ("sentence"));
                }
            }
        } catch (GLib.RegexError re) {
            warning ("%s".printf(re.message));
        }

        return res;
    }
}
