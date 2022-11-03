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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/trashlistview.ui")]
public class Notejot.TrashListView : He.Bin {
    [GtkChild]
    unowned Gtk.SingleSelection selection_model;

    public ObservableList<Trash>? trashs { get; set; }
    public TrashViewModel? tview_model { get; set; }
    public Bis.Album album { get; construct; }

    Trash? _selected_trash;
    public Trash? selected_trash {
        get { return _selected_trash; }
        set {
            if (value == _selected_trash)
                return;

            _selected_trash = value;
        }
    }

    public TrashListView () {
        Object (
            album: album
        );
    }

    construct {
        selection_model.bind_property ("selected", this, "selected-trash", DEFAULT, (_, from, ref to) => {
            var pos = (uint) from;

            if (pos != Gtk.INVALID_LIST_POSITION)
                to.set_object (selection_model.model.get_item (pos));
                ((Bis.Album)MiscUtils.find_ancestor_of_type<Bis.Album>(this)).set_visible_child (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).grid);

            return true;
        });
    }

    public signal void new_trash_requested ();
}
