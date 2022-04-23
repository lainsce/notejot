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
namespace Notejot.MiscUtils {
    public T find_ancestor_of_type<T> (Gtk.Widget? ancestor) {
      while ((ancestor = ancestor.get_parent ()) != null) {
        if (ancestor.get_type ().is_a (typeof (T)))
          return (T) ancestor;
      }

      return null;
    }

    public async File? display_save_dialog (MainWindow win) {
        var chooser = new Gtk.FileChooserNative (null, win, Gtk.FileChooserAction.SAVE, null, null);
        chooser.set_transient_for(win);
        var filter1 = new Gtk.FileFilter ();
        filter1.set_filter_name (_("Markdown files"));
        filter1.add_pattern ("*.md");
        chooser.add_filter (filter1);
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("All files"));
        filter.add_pattern ("*");
        chooser.add_filter (filter);

        var response = yield run_dialog_async (chooser);

        if (response == Gtk.ResponseType.ACCEPT) {
            return chooser.get_file ();
        }

        return null;
    }

    public async File? display_open_dialog (MainWindow win) {
        var chooser = new Gtk.FileChooserNative (null, win, Gtk.FileChooserAction.OPEN, null, null);
        chooser.set_transient_for(win);
        var filter1 = new Gtk.FileFilter ();
        filter1.set_filter_name (_("Image files"));
        filter1.add_pattern ("*.png");
        filter1.add_pattern ("*.gif");
        filter1.add_pattern ("*.jpg");
        filter1.add_pattern ("*.jpeg");
        chooser.add_filter (filter1);
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("All files"));
        filter.add_pattern ("*");
        chooser.add_filter (filter);

        var response = yield run_dialog_async (chooser);

        if (response == Gtk.ResponseType.ACCEPT) {
            return chooser.get_file ();
        }

        return null;
    }

    private async Gtk.ResponseType run_dialog_async (Gtk.FileChooserNative dialog) {
        var response = Gtk.ResponseType.CANCEL;

        dialog.response.connect (r => {
        	response = (Gtk.ResponseType) r;

        	run_dialog_async.callback ();
        });

        dialog.show ();

        yield;
        return response;
	}
}
