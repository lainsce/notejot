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
    public class Application : Gtk.Application {
        public static GLib.Settings gsettings;
        public MainWindow note = null;
        
        public Application () {
            Object (
                application_id: "com.github.lainsce.notejot"
            );
        }
        
        static construct {
            gsettings = new GLib.Settings ("com.github.lainsce.notejot");
        }
        
        construct {
            var delete_action = new SimpleAction ("delete", null);
            set_accels_for_action ("app.delete", {"<Control>w"});
            add_action (delete_action);
            delete_action.activate.connect (() => {
                MainWindow note = (MainWindow)get_active_window ();
                note.destroy();
            });
        }
        
        protected override void activate () {
            note = new MainWindow(this);
        }
        
        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            
            var app = new Application();
            return app.run(args);
        }
    }
}
