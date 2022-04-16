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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notegridview.ui")]
public class Notejot.NoteGridView : View {
    [GtkChild]
    public unowned Gtk.Button back_button;
    [GtkChild]
    public unowned Adw.HeaderBar stitlebar;

    public ObservableList<Note>? notes { get; set; }
    public Gtk.SingleSelection? ss {get; construct;}
    public Adw.Leaflet leaf { get; construct; }

    Note? _selected_note;
    public Note? selected_note {
        get { return _selected_note; }
        set {
            if (value == _selected_note)
                return;

            _selected_note = value;
        }
    }
    public NoteViewModel? view_model { get; set; }

    public NoteGridView () {
        Object (
            ss: ss,
            leaf: leaf
        );
    }

    construct {
        ss.bind_property ("selected", this, "selected-note", DEFAULT, (_, from, ref to) => {
            var pos = (uint) from;

            if (pos != Gtk.INVALID_LIST_POSITION)
                to.set_object (ss.model.get_item (pos));
                if (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).sgrid.get_visible_child_name () == "notegrid") {
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).sgrid.set_visible (false);
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).grid.set_visible (true);
                }
                ((Adw.Leaflet)MiscUtils.find_ancestor_of_type<Adw.Leaflet>(this)).set_visible_child (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).grid);

            return true;
        });

        leaf.bind_property ("folded", back_button, "visible", SYNC_CREATE);

        back_button.clicked.connect (() => {
            ((Adw.Leaflet)MiscUtils.find_ancestor_of_type<Adw.Leaflet>(this)).set_visible_child (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).nbgrid);
        });
    }

    public signal void new_note_requested ();
}
