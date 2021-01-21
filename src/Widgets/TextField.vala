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
namespace Notejot {
    public class Widgets.TextField : Gtk.TextView {
        public MainWindow win;
        public string text = "";

        public TextField (MainWindow win) {
            this.win = win;
            this.editable = true;
            this.get_style_context ().add_class ("notejot-tview");

            // Sane defaults
            this.set_wrap_mode (Gtk.WrapMode.WORD);
            this.left_margin = this.right_margin = this.bottom_margin = 40;
            this.set_pixels_inside_wrap((int)(1.5*4));
            this.set_pixels_above_lines((int)(1.5*4));
            this.set_pixels_below_lines((int)(1.5*4));
            this.has_focus = true;

            this.get_buffer ().set_text (this.text);
            win.tm.save_notes ();
            this.show_all ();
        }
    }
}
