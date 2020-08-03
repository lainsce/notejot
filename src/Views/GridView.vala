/*
* Copyright (c) 2017-2020 Lains
*
* This program is free software; you can redistribute it and/or
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
    public class Views.GridView : Gtk.Grid {
        public MainWindow win;
        public Widgets.FlowGrid flowgrid;

        public GridView (MainWindow win) {
            this.win = win;

            flowgrid = new Widgets.FlowGrid (win);

            var flowgrid_scroller = new Gtk.ScrolledWindow (null, null);
            flowgrid_scroller.add (flowgrid);

            this.add (flowgrid_scroller);
            this.show_all ();
        }
    }
}