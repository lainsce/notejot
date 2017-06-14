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

using Gtk;
using Granite;

namespace Notejot.Widgets {
    public class Toolbar : Gtk.HeaderBar {
        private Gtk.Button clear_button;
        private Widgets.ColorPicker color_button;

        public File file;

        public Toolbar () {
            var header_context = this.get_style_context ();
            header_context.add_class ("notejot-toolbar");

            clear_button = new Gtk.Button ();
            clear_button.set_image (new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            clear_button.has_tooltip = true;
            clear_button.tooltip_text = (_("Clear note"));

            clear_button.clicked.connect (() => {
                Widgets.SourceView.buffer.set_text ("");
                Utils.FileUtils.save_tmp_file ();
            });

            color_button = new Widgets.ColorPicker ();

            this.pack_end (clear_button);
            this.pack_end (color_button);

            this.show_close_button = true;
            this.show_all ();
        }
    }
}
