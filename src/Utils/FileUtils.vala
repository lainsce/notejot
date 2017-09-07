/*
 * Copyright (C) 2017 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Notejot.Utils.FileUtils {
    File tmp_file;

    public void save_file (File file, uint8[] buffer) throws Error {
        var output = new DataOutputStream (file.create
                (FileCreateFlags.NONE));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
    }

    private void load_tmp_file () {
        string cache_path = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.notejot");
        var cache_folder = File.new_for_path (cache_path);
        if (!cache_folder.query_exists ()) {
            try {
                cache_folder.make_directory_with_parents ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        tmp_file = cache_folder.get_child ("temp");

        if ( !tmp_file.query_exists () ) {
            try {
                tmp_file.create (FileCreateFlags.NONE);
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        try {
            string text;
            string filename = tmp_file.get_path ();
            GLib.FileUtils.get_contents (filename, out text);
            Widgets.SourceView.buffer.text = text;
        } catch (Error e) {
            warning ("%s", e.message);
        }
    }

    private void save_tmp_file () {
        if ( tmp_file.query_exists () ) {
            try {
                tmp_file.delete();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        Gtk.TextIter start, end;
        Widgets.SourceView.buffer.get_bounds (out start, out end);
        string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (tmp_file, binbuffer);
        } catch (Error e) {
            warning ("Exception found: "+ e.message);
        }
    }
}
