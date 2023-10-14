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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notelistview.ui")]
public class Notejot.NoteListView : He.Bin {
    [GtkChild]
    public unowned Gtk.ListView lv;
    [GtkChild]
    public unowned Gtk.SingleSelection ss;

    public ObservableList<Note>? notes { get; set; }
    public Note? selected_note { get; set; }
    public NotebookMainListView? nblistview { get; set; }
    public He.TextField? note_search { get; set; }
    public NoteViewModel? view_model { get; set; }
    public NotebookViewModel? nbview_model { get; set; }
    public Bis.Album album { get; construct; }

    public NoteListView () {
        Object (
            album: album
        );
    }

    construct {
        lv.activate.connect ((pos) => {
            if ((lv.get_model ().get_item (pos) as Note) != selected_note) {
                selected_note = lv.get_model ().get_item (pos) as Note;
            } else {
                ss.unselect_all ();
            }
            album.set_visible_child (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).grid);
        });
    }

    public signal void new_note_requested ();
}

