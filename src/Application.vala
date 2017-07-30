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
namespace Notejot {
    public class Application : Granite.Application {
        private MainWindow window = null;

        public Application () {
            Object (application_id: "com.github.lainsce.notejot",
                    flags: ApplicationFlags.FLAGS_NONE);
        }

        construct {
            app_icon = "com.github.lainsce.notejot";
            exec_name = "com.github.lainsce.notejot";
            app_launcher = "com.github.lainsce.notejot";

            var quit_action = new SimpleAction ("quit", null);
            add_action (quit_action);
            add_accelerator ("<Control>q", "app.quit", null);
            quit_action.activate.connect (() => {
                if (window != null) {
                    window.destroy ();
                }
            });
        }

        protected override void activate () {
            new_window ();
        }

        public static int main (string[] args) {
            var app = new Notejot.Application ();
            return app.run (args);
        }

        public void new_window () {
            if (window != null) {
                window.present ();
                return;
            }

            window = new MainWindow (this);
            window.show_all ();
        }
    }
}
