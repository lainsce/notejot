/*
* Copyright (c) 2017 Robert San <robertsanseries@gmail.com> (http://robertsanseries.github.io)
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

using Gtk;
using Granite;

namespace Notejot.Widgets {
    public class Toolbar : Gtk.HeaderBar {
        public signal void about_selected ();

        private Gtk.Menu menu;
        private Gtk.MenuButton app_menu;

        public Widgets.SourceView view;

        public Toolbar() {
            icon_settings ();
            this.show_close_button = true;
            this.show_all ();
        }

        private void icon_settings () {
            this.app_menu = new Gtk.MenuButton();
            this.app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            this.app_menu.has_tooltip = true;
            this.app_menu.tooltip_text = ("Settings");

            menu_settings();

            this.app_menu.popup = this.menu;
            this.pack_end (this.app_menu);
        }

        private void menu_settings () {
            this.menu = new Gtk.Menu ();

            var save_item = new Gtk.MenuItem.with_label ("Save as…");
            save_item.activate.connect(() => {
                save_file_as_dialog ();
            });

            var about_item = new Gtk.MenuItem.with_label ("About");
            about_item.activate.connect(() => {
                show_about_dialog ();
            });

            this.menu.add (save_item);
            this.menu.add (new Gtk.SeparatorMenuItem ());
            this.menu.add (about_item);
            this.menu.show_all ();
        }

        private static void show_about_dialog () {
            Granite.Widgets.AboutDialog aboutDialog = new Granite.Widgets.AboutDialog();
            aboutDialog.program_name        = "Notejot";
            aboutDialog.website             = "https://github.com/lainsce/notejot/";
            aboutDialog.website_label       = "Website";
            aboutDialog.logo_icon_name      = "com.github.lainsce.notejot";
            aboutDialog.version             = "0.1.5";
            aboutDialog.authors             = { "Lains <lainsce@airmail.cc>" };
            aboutDialog.comments            = "Jot your ideas.";
            aboutDialog.license_type        = Gtk.License.GPL_3_0;
            aboutDialog.help                = "https://github.com/lainsce/notejot/";
            aboutDialog.bug                 = "https://github.com/lainsce/notejot/issues";
            aboutDialog.response.connect(() => {
              aboutDialog.destroy ();
            });
        }

        public void save_file_as_dialog () {
            Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
                "Save Text File",
                null,
                Gtk.FileChooserAction.SAVE,
                "Cancel", Gtk.ResponseType.CANCEL,
                "Save", Gtk.ResponseType.ACCEPT
            );

            Gtk.FileFilter filter = new Gtk.FileFilter ();
            chooser.set_filter (filter);
            filter.add_mime_type ("text/*");

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                save_file_as (chooser.get_filename (), view.buffer.text);
                debug("File was saved.");
            }

            chooser.close ();
        }

        public void save_file_as (string filename, string text) {
            try {
                File file = File.new_for_path (filename);
                var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
                var data_stream = new DataOutputStream (file_stream);
                debug(text);
                data_stream.put_string (text);
            } catch (Error e) {
                stderr.printf ("Error: couldn't save %s\n", e.message);
            }
        }
    }
}
