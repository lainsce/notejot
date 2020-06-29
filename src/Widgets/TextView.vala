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
        public new unowned Gtk.TextBuffer buffer;

        public string text {
            owned get {
                return buffer.text;
            }
            set {
                buffer.text = value;
            }
        }

        public TextView (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.left_margin = this.right_margin = 12;
        }

        construct {
            this.get_style_context ().add_class ("notejot-tview");
            var buffer = new Gtk.TextBuffer (null);
            this.buffer = buffer;
            set_buffer (buffer);

            buffer.text = text;
        }
    }
}
