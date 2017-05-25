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

    // Save a buffer to a file.
    public void save_file (File file, uint8[] buffer) throws Error {
        var output = new DataOutputStream (file.create
                (FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
        // No close method? This is scary, GLib. Very scary.
    }

    // Read a file and get the contents.
    public string open_file (File file) throws Error {
        string content = "";
        var input = new DataInputStream (file.read ());
        string line;
        while ((line = input.read_line (null)) != null)
            content += line + "\n";
        return content;
    }

}
