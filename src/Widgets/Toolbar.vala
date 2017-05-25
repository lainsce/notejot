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
            app_menu = new Gtk.MenuButton();
            app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            app_menu.has_tooltip = true;
            app_menu.tooltip_text = (_("Settings"));

            menu = new Gtk.Menu ();

            var save_item = new Gtk.MenuItem.with_label (_("Save as…"));
            save_item.activate.connect(() => {
                save_file_as_dialog ();
            });

            var about_item = new Gtk.MenuItem.with_label (_("About"));
            about_item.activate.connect(() => {
                show_about_dialog ();
            });

            menu.add (save_item);
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (about_item);
            menu.show_all ();

            app_menu.popup = menu;
            this.pack_end (app_menu);

            this.show_close_button = true;
            this.show_all ();
        }

        private static void show_about_dialog () {
            Granite.Widgets.AboutDialog aboutDialog = new Granite.Widgets.AboutDialog();
            aboutDialog.program_name        = "Notejot";
            aboutDialog.website             = "https://github.com/lainsce/notejot/";
            aboutDialog.website_label       = "Website";
            aboutDialog.logo_icon_name      = "com.github.lainsce.notejot";
            aboutDialog.version             = "0.1.6";
            aboutDialog.authors             = { "Lains <lainsce@airmail.cc>" };
            aboutDialog.comments            = "Jot your ideas.";
            aboutDialog.license_type        = Gtk.License.GPL_3_0;
            aboutDialog.help                = "https://github.com/lainsce/notejot/";
            aboutDialog.bug                 = "https://github.com/lainsce/notejot/issues";
            aboutDialog.translator_credits  = "Github Translators";
            aboutDialog.translate           = "https://github.com/lainsce/notejot/tree/master/po";
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
                Gtk.TextIter start;
                Gtk.TextIter end;
                view.buffer.get_start_iter(out start);
                view.buffer.get_end_iter(out end);

                try {
                    FileUtils.set_contents (chooser.get_filename(), view.buffer.get_text(start, end, false));
                } catch (Error e) {
                    stderr.printf ("Error: couldn't save %s\n", e.message);
                }
            }
            chooser.close ();
        }
    }
}
