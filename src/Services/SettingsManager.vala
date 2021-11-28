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
[SingleInstance]
public class Notejot.Settings : Object {
    private GLib.Settings settings = new GLib.Settings ("io.github.lainsce.Notejot");
    public bool is_maximized { get; set; }
    public string last_view { get; set; }
    public string font_size { get; set; }
    public int window_w { get; set; }
    public int window_h { get; set; }
    public int schema_version { get; set; }

    construct {
        settings.bind ("last-view", this, "last-view", DEFAULT);
        settings.bind ("font-size", this, "font-size", DEFAULT);
        settings.bind ("window-w", this, "window-w", DEFAULT);
        settings.bind ("window-h", this, "window-h", DEFAULT);
        settings.bind ("schema-version", this, "schema-version", DEFAULT);
    }

    public Action create_action (string key) {
        return settings.create_action (key);
    }
}
