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
    public class Views.GridView : Gtk.Grid {
        private MainWindow win;
        public Widgets.FlowGrid grid;

        public GridView (MainWindow win) {
            this.win = win;
            this.get_style_context ().add_class ("notejot-lview");
            grid = new Widgets.FlowGrid (win);

            var grid_scroller = new Gtk.ScrolledWindow (null, null) {
                margin_top = 6
            };
            grid_scroller.add (grid);

            this.attach (grid_scroller, 0, 1);
            this.orientation = Gtk.Orientation.VERTICAL;
            this.show_all ();
        }
    }
}