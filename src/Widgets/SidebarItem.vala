/*
* Copyright (C) 2017-2020 Lains
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
    public class Widgets.SidebarItem : Granite.Widgets.SourceList.Item {
        private MainWindow win;

        public string title {
            set {
                this.markup = value;
            }
        }

        public SidebarItem (MainWindow win, string title, string contents) {
            this.title = title;
            this.win = win;

            var icon = new ThemedIcon ("emblem-documents-symbolic");

            this.selectable = true;
            this.icon = icon;
            this.tooltip = (_("This is a note."));

            this.activated.connect (() => {
                if (this != null && win.editablelabel != null && win.stack != null) {
                    win.editablelabel.text = title;
                    win.textfield.text = contents;
                    win.textfield.update_html_view ();
                    win.stack.set_visible_child (win.note_view);
                    win.format_button.sensitive = true;
                }
            });
        }

        public void destroy_item () {
            win.notes_category.remove(this);
        }
    }
}