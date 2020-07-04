/*
* Copyright (C) 2017-2020 Lains
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
namespace Notejot {
    public class Widgets.TextView : Gtk.TextView {
        public MainWindow win;
        public new Gtk.TextBuffer buffer;

        public TextView (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.left_margin = this.right_margin = 12;
            this.get_style_context ().add_class ("notejot-tview");
        }

        construct {
            buffer = new Gtk.TextBuffer (null);
            buffer.text = formatted_text (win);
            set_buffer (buffer);
        }

        public string formatted_text (MainWindow win) {
            var tmp_buffer = new Gtk.TextBuffer (null);
            bool bold_lock = false;
            Gtk.TextIter start, end, start2, end2, begin_iter, end_iter, tmp_iter, tmp_iter2;

            tmp_buffer.get_start_iter(out start);
            tmp_buffer.get_end_iter(out end);

            buffer.get_start_iter(out start2);
            buffer.get_end_iter(out end2);

            var deserialization = tmp_buffer.register_deserialize_tagset (null);
            var format = tmp_buffer.register_serialize_tagset (null);
            tmp_buffer.deserialize(tmp_buffer, deserialization, start, tmp_buffer.serialize(buffer, format, start2, end2));

            Gtk.TextMark begin_mark = tmp_buffer.create_mark(null, start, false);
            Gtk.TextMark end_mark = tmp_buffer.create_mark(null, start, true);

            tmp_buffer.get_iter_at_mark(out begin_iter, begin_mark);
            if (begin_iter.begins_tag(win.bold_font) && !bold_lock) {
                tmp_buffer.insert(ref begin_iter, "[b]", -1);
                bold_lock = true;
            }
            tmp_buffer.get_iter_at_mark(out end_iter, end_mark);
            if (end_iter.ends_tag(win.bold_font) && bold_lock) {
                tmp_buffer.insert(ref end_iter, "[/b]", -1);
                bold_lock = false;
            }

            tmp_buffer.get_iter_at_mark (out tmp_iter, begin_mark);
            var tmp_var = tmp_iter.forward_to_tag_toggle (null);

            while (tmp_var) {
                begin_mark = tmp_buffer.create_mark(null, tmp_iter, false);
                end_mark = tmp_buffer.create_mark(null, tmp_iter, true);

                tmp_buffer.get_iter_at_mark(out begin_iter, begin_mark);
                if (begin_iter.begins_tag(win.bold_font) && !bold_lock) {
                    tmp_buffer.insert(ref begin_iter, "[b]", 3);
                    bold_lock = true;
                }
                tmp_buffer.get_iter_at_mark(out end_iter, end_mark);
                if (end_iter.ends_tag(win.bold_font) && bold_lock) {
                    tmp_buffer.insert(ref end_iter, "[/b]", 3);
                    bold_lock = false;
                }

                tmp_var = tmp_iter.forward_to_tag_toggle (null);
            }

            string text = tmp_buffer.get_text(start, end, true);

            return text;
        }
    }
}
