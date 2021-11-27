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
public class Notejot.ObservableList<T> : Object, ListModel {
    List<T> data = new List<T> ();

    public void add (T item) {
        var position = data.length ();

        data.append (item);

        items_changed (position, 0, 1);
    }

    public void add_all (List<T> items) {
        var position = data.length ();

        foreach (var item in items)
            data.append (item);

        items_changed (position, 0, items.length ());
    }

    public void remove_all () {
        var current_size = data.length ();

        foreach (var i in data)
            data.remove (i);

        items_changed (0, current_size, 0);
    }

    public new T @get (uint index) {
        return data.nth_data (index);
    }

    public bool remove (T item) {
        var position = data.index (item);

        if (position == -1)
            return false;

        data.remove (item);
        items_changed (position, 1, 0);

        return true;
    }

    Object? get_item (uint position) {
        return this[position] as Object;
    }

    Type get_item_type () {
        return typeof (T);
    }

    uint get_n_items () {
        return data.length ();
    }
}
