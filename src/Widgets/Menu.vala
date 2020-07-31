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
    public class Widgets.Menu : Gtk.MenuButton {
        private MainWindow win;
        public Gtk.Switch applet_switch;
        public Gtk.Switch mode_switch;

        public Menu (MainWindow win) {
            this.win = win;

            var interface_header = new Granite.HeaderLabel (_("Interface"));
            var alabel = new Gtk.Label (_("Applet Mode:"));
            alabel.halign = Gtk.Align.END;
            applet_switch = new Gtk.Switch ();
            applet_switch.valign = Gtk.Align.CENTER;
            Notejot.Application.gsettings.bind ("pinned", applet_switch, "active", SettingsBindFlags.DEFAULT);
            applet_switch.has_focus = false;

            var dlabel = new Gtk.Label (_("Dark Mode:"));
            dlabel.halign = Gtk.Align.END;
            mode_switch = new Gtk.Switch ();
            mode_switch.valign = Gtk.Align.CENTER;
            Notejot.Application.gsettings.bind ("dark-mode", mode_switch, "active", SettingsBindFlags.DEFAULT);
            mode_switch.has_focus = false;

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 12;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.attach (interface_header, 0, 0, 1, 1);
            menu_grid.attach (dlabel, 0, 1, 1, 1);
            menu_grid.attach (mode_switch, 1, 1, 1, 1);
            menu_grid.attach (alabel, 0, 2, 1, 1);
            menu_grid.attach (applet_switch, 1, 2, 1, 1);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            this.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON));
            this.has_tooltip = true;
            this.tooltip_text = (_("Settings"));
            this.popover = menu;
        }
    }
}