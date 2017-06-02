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
        private Gtk.Button new_button;
        private Gtk.Button open_button;
        private Gtk.Button save_button;

        public File file;

        public Toolbar() {
			var header_context = this.get_style_context ();
            header_context.add_class ("notejot-toolbar");

            new_button = new Gtk.Button ();
            new_button.set_image (new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
			new_button.has_tooltip = true;
            new_button.tooltip_text = (_("Clear note"));

            new_button.clicked.connect(() => {
                Widgets.SourceView.buffer.set_text ("");
                Utils.FileUtils.save_tmp_file ();
            });

            save_button = new Gtk.Button ();
            save_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
			save_button.has_tooltip = true;
            save_button.tooltip_text = (_("Save as…"));

            save_button.clicked.connect(() => {
                save_button_pressed ();
            });

            open_button = new Gtk.Button ();
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
			open_button.has_tooltip = true;
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect(() => {
                open_button_pressed ();
            });

            this.pack_start (new_button);
            this.pack_end (save_button);
            this.pack_end (open_button);

            this.show_close_button = true;
            this.show_all ();
        }

        public void open_button_pressed () {
            debug ("Open button pressed.");

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Opening file...");
                    open_document ();
                } catch (Error e) {
                    error ("Unexpected error during open: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public void save_button_pressed () {
            debug ("Save button pressed.");

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Saving file...");
                    save_document ();
                } catch (Error e) {
                    error ("Unexpected error during save: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public bool open_document () throws Error {
            // If it's a file, ask the user for a valid location.
            if (file == null) {
                debug ("Asking the user what to open.");
                file = Utils.DialogUtils.display_open_dialog ();
                // If file is still null, then user aborted open operation.
                if (file == null) {
                    debug ("User cancelled operation. Aborting.");
                    return false;
                }
            }

            string text;
            FileUtils.get_contents (file.get_path(), out text);

            Widgets.SourceView.buffer.text = text;
            return true;
        }

        public bool save_document () throws Error {
            // If it's a new file, ask the user for a valid location.
            if (file == null) {
                debug ("Asking the user where to save.");
                file = Utils.DialogUtils.display_save_dialog ();
                // If file is still null, then user aborted save operation.
                if (file == null) {
                    debug ("User cancelled operation. Aborting.");
                    return false;
                }
            }

            if (file.query_exists ())
                file.delete ();

            Gtk.TextIter start, end;
            Widgets.SourceView.buffer.get_bounds (out start, out end);
            string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;
            Utils.FileUtils.save_file (file, binbuffer);
            return true;
        }
    }
}
