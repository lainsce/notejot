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

        private static bool print_version = false;
        private static bool show_about_dialog = false;

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            application_id = "com.github.lainsce.notejot";
            program_name = "Notejot";
            app_years = "2017";
            exec_name = "com.github.lainsce.notejot";
            app_launcher = "com.github.lainsce.notejot";
            build_version = "1.0.8";
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
            var app = new Notejot.Application ();
            return app.run (args);
        }

        public void new_window () {
            new MainWindow (this).show_all ();
        }

        protected override int command_line (ApplicationCommandLine command_line) {
            string[] args = command_line.get_arguments ();

            var context = new OptionContext ("File");
            context.add_main_entries (entries, "com.github.lainsce.notejot");
            context.add_group (Gtk.get_option_group (true));

            try {
                unowned string[] tmp = args;
                context.parse (ref tmp);
            } catch (Error e) {
                stdout.printf ("com.github.lainsce.notejot: ERROR: " + e.message + "\n");
                return 0;
            }

            if (print_version) {
                stdout.printf ("Notejot %s\n", this.build_version);
                stdout.printf ("Copyright 2017 Lains\n");
            } else {
                new_window ();
            }
            return 0;
        }

        static const OptionEntry[] entries = {
            { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
            { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
            { null }
        };
    }
}
