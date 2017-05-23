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

public class Notejot : Gtk.Application {
    public Notejot () {
        Object (application_id: "com.github.lainsce.notejot");
    }

    protected override void activate () {
        var app_window = new MainWindow (this);

        var settings = new Settings ("com.github.lainsce.notejot");
        var window_x = settings.get_int ("window-x");
        var window_y = settings.get_int ("window-y");

        if (window_x != -1 ||  window_y != -1) {
            app_window.move (window_x, window_y);
        }

        app_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/lainsce/notejot/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        quit_action.activate.connect (() => {
            if (app_window != null) {
                app_window.destroy ();
            }
        });

        app_window.state_changed.connect (() => {
            int root_x, root_y;
            app_window.get_position (out root_x, out root_y);
            settings.set_int ("window-x", root_x);
            settings.set_int ("window-y", root_y);
        });
    }

    public static int main (string[] args) {
        var app = new Notejot ();
        return app.run (args);
    }
}
