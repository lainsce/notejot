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

        private Gtk.Box headerbar_box;
        private Gtk.Menu menu;
        private Gtk.MenuButton app_menu;

        public const string FILE_EXTENSION = ".txt";
        public static File? current_file = null;

        public Toolbar() {
            this.headerbar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            icon_settings ();

            this.show_close_button = true;
            this.set_custom_title (headerbar_box);
            this.headerbar_box.no_show_all = false;
            this.headerbar_box.show ();
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

            var save_item = new Gtk.MenuItem.with_label ("Save as...");
            save_item.activate.connect(() => {
               save_selected ();
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

        private static File? get_file_from_user (string title, string accept_button_label, Gtk.FileChooserAction chooser_action, List<Gtk.FileFilter> filters) {
            File? result = null;

            var dialog = new Gtk.FileChooserDialog (
                title,
                null,
                chooser_action,
                ("Cancel"), Gtk.ResponseType.CANCEL,
                accept_button_label, Gtk.ResponseType.ACCEPT);

            var all_filter = new Gtk.FileFilter ();
            all_filter.set_filter_name ("All Files");
            all_filter.add_pattern ("*");

            filters.append (all_filter);

            filters.@foreach ((filter) => {
                dialog.add_filter (filter);
            });

            if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                result = dialog.get_file ();
            }

            dialog.close ();

            return result;
        }

        public static File? save_selected () {
            File? result = null;
            List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();
            Gtk.FileFilter filter = new Gtk.FileFilter ();
            filter.set_filter_name ("Text Files");
            filter.add_pattern ("*" + FILE_EXTENSION);
            filters.append (filter);

            result = get_file_from_user (("Save file"), ("Save"), Gtk.FileChooserAction.SAVE, filters);

            var path = result.get_path ();
            if (!path.has_suffix (FILE_EXTENSION)) {
                result = File.new_for_path (path + FILE_EXTENSION);
            }

            return result;
        }
    }
}
