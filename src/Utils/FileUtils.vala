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
namespace Notejot.FileUtils {
    async bool create_text_file (string filename, string contents, Cancellable? cancellable = null) throws Error {
        return yield ThreadUtils.run_in_thread<bool> (() => {
            var dir_path = Path.build_filename (Environment.get_user_data_dir (), "/io.github.lainsce.Notejot/");

            if (DirUtils.create_with_parents (dir_path, 0755) != 0) {
                throw new Error (FileError.quark (), GLib.FileUtils.error_from_errno (errno), "%s", strerror (errno));
            }

            var file_path = Path.build_filename (dir_path, filename);
            GLib.FileUtils.set_contents (file_path, contents);

            return true;
        });
    }

    async string? read_text_file (string filename, Cancellable? cancellable = null) throws Error {
        return yield ThreadUtils.run_in_thread<string?> (() => {
            var file_path = Path.build_filename (Environment.get_user_data_dir (), "/io.github.lainsce.Notejot/", filename);

            string contents = "";

            try {
                GLib.FileUtils.get_contents (file_path, out contents);
            } catch (Error err) {
                if (err is FileError.NOENT)
                    return null;

                throw err;
            }

            return contents;
        });
    }
}
