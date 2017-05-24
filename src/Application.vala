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
public class Notejot.Application : Granite.Application {

    construct {
        application_id = "com.github.lainsce.notejot";
        program_name = "Notejot";
        app_years = "2017";
        exec_name = "com.github.lainsce.notejot";
        app_launcher = "com.github.lainsce.notejot";
        build_version = "0.1.5";
        app_icon = "com.github.lainsce.notejot";
        main_url = "https://github.com/lainsce/notejot/";
        bug_url = "https://github.com/lainsce/notejot/issues";
        help_url = "https://github.com/lainsce/notejot/";
        about_authors = {"Lains <lainsce@airmail.cc>", null};
        about_license_type = Gtk.License.GPL_3_0;
    }

    protected override void activate () {
        var app_window = new MainWindow (this);
        app_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);

        quit_action.activate.connect (() => {
            if (app_window != null) {
                app_window.destroy ();
            }
        });
    }

    public static int main (string[] args) {
        var app = new Notejot.Application ();
        return app.run (args);
    }
}
