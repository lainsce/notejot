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
public abstract class Notejot.View : Gtk.Widget, Gtk.Buildable {
  Adw.Bin? child_bin = new Adw.Bin () { vexpand = true };

  public Gtk.Widget? child {
    get { return child_bin.child; }
    set { child_bin.child = value; }
  }

  construct {
    layout_manager = new Gtk.BoxLayout (VERTICAL);

    child_bin?.set_parent (this);
  }

  protected override void dispose () {
    child_bin?.unparent ();
    child_bin = null;

    base.dispose ();
  }

  void add_child (Gtk.Builder builder, Object child, string? type) {
    if (child is Gtk.Widget) {
      this.child = (Gtk.Widget) child;
      return;
    }

    base.add_child (builder, child, type);
  }
}
