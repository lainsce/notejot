/*
* Copyright (c) 2017-2020 Lains
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
    public class Views.WelcomeView : Gtk.Grid {
        private MainWindow win;

        public WelcomeView (MainWindow win) {
            this.win = win;
            
            var normal_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DND);
            var normal_label = new Gtk.Label (_("Start by adding some notes…"));
            var normal_label_context = normal_label.get_style_context ();
            normal_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            normal_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            this.add (normal_icon);
            this.add (normal_label);
            this.column_spacing = 12;
            this.margin = 24;
            this.expand = true;
            this.valign = Gtk.Align.CENTER;
            this.halign = Gtk.Align.CENTER;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.show_all ();
        }
    }
}