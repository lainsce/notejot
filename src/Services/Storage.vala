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
*
*/

namespace Notejot {
    public class Storage : Object {
        public string color;
        public string selected_color_text;
        public bool pinned;
        public int64 x;
        public int64 y;
        public string content;
        public string title;

        public Storage() {}

        public Storage.from_storage(int64 x, int64 y, string color, string selected_color_text, bool pinned, string message, string title) {
            this.color = color;
            this.selected_color_text = selected_color_text;
            this.pinned = pinned;
            this.content = message;
            this.x = x;
            this.y = y;
            this.title = title;
        }
    }
}
