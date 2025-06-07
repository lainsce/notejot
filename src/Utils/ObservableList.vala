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
public class Notejot.ObservableList<T>: Object, ListModel {
    List<T> data = new List<T> ();

    public void add (T item) {
        var position = data.length ();
        data.append (item);
        items_changed (position, 0, 1);
    }

    public void add_all (List<T> items) {
        if (items == null || items.length () == 0)
            return;

        var position = data.length ();
        var added = 0;

        foreach (var item in items) {
            data.append (item);
            added++;
        }

        if (added > 0) {
            items_changed (position, 0, added);
        }
    }

    public void remove_all () {
        var size = data.length ();
        if (size == 0)
            return;

        data = new List<T> ();
        items_changed (0, size, 0);
    }

    public new T @get (uint index) {
        if (index >= data.length ())
            return null;
        return data.nth_data (index);
    }

    public bool remove (T item) {
        if (item == null)
            return false;

        int pos = data.index (item);
        if (pos < 0)
            return false;

        List<T> new_list = new List<T> ();
        int i = 0;
        foreach (T current in data) {
            if (i != pos) {
                new_list.append (current);
            }
            i++;
        }
        data = (owned) new_list;
        items_changed ((uint) pos, 1, 0);
        return true;
    }

    Object ? get_item (uint position) {
        if (position >= data.length ())
            return null;
        return this[position] as Object;
    }

    Type get_item_type () {
        return typeof (T);
    }

    uint get_n_items () {
        return data.length ();
    }
}