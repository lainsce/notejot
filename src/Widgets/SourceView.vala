/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

namespace Notejot.Widgets {
    public class SourceView : Gtk.SourceView {
        public static new Gtk.SourceBuffer buffer;
        public static bool is_modified;

        construct {
            var context = this.get_style_context ();
            context.add_class ("notejot-note");

            buffer = new Gtk.SourceBuffer (null);
            this.set_buffer (buffer);

            is_modified = false;
            buffer.changed.connect (on_text_modified);

            this.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            this.margin = 1;
            this.left_margin = 12;
            this.top_margin = 12;
            this.right_margin = 12;
            this.expand = false;
            this.set_highlight_matching_brackets (false);
        }

        public void on_text_modified () {
            Utils.FileUtils.save_tmp_file ();
            if (!is_modified) {
                is_modified = true;
            }
        }
    }
}
