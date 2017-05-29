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

        private Notejot.MainWindow? window = null;

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

            application_id = "com.github.lainsce.notejot";
            program_name = "Notejot";
            app_years = "2017";
            exec_name = "com.github.lainsce.notejot";
            app_launcher = "com.github.lainsce.notejot";
            build_version = "1.0.4";
            app_icon = "com.github.lainsce.notejot";
            main_url = "https://github.com/lainsce/notejot/";
            bug_url = "https://github.com/lainsce/notejot/issues";
            help_url = "https://github.com/lainsce/notejot/";
            about_authors = {"Lains <lainsce@airmail.cc>", null};
            about_license_type = Gtk.License.GPL_3_0;

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
            if (window == null) {
                window = new MainWindow (this);
                add_window (window);
                window.show_all ();
            } else {
                window.present ();
            }
        }

        public static int main (string[] args) {
            Gtk.init (ref args);

            var app = new Notejot.Application ();
            if ("--help" in args || "-h" in args) {
                return ((Gtk.Application)app).run (args);
            } else {
                return app.run (args);
            }
        }

        private int _command_line (ApplicationCommandLine command_line) {
            string[] args = command_line.get_arguments ();

            try {
                var opt_context = new OptionContext ("- Notejot");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (options, null);

                unowned string[] tmp = args;
                opt_context.parse (ref tmp);
            } catch (OptionError e) {
                command_line.print ("error: %s\n", e.message);
                command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                return 0;
            }
            return 0;
        }

        public override int command_line (ApplicationCommandLine commmand_line) {
            this.hold ();
            int res = _command_line (commmand_line);
            this.release ();

            return res;
          }
     }
}
