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
class Notejot.NoteSorter : Gtk.Sorter {
  protected override Gtk.Ordering compare (Object? item1, Object? item2) {
    var note1 = item1 as Note;
    var note2 = item2 as Note;

    if (note1 == null || note2 == null)
      return EQUAL;

    if (note1.pinned || note2.pinned) {
        return LARGER;
    } else {
        return Gtk.Ordering.from_cmpfunc (note1.subtitle.collate (note2.subtitle));
    }
  }

  protected override Gtk.SorterOrder get_order () {
    return TOTAL;
  }
}
