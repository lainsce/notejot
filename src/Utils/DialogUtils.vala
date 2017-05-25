/*
 * Copyright (C) 2017 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Notejot.Utils.DialogUtils {

    /**
     * Display a choose file dialog: a save dialog, or an open dialog.
     */
    public Gtk.FileChooserDialog create_file_chooser (string title,
            Gtk.FileChooserAction action) {
        // Init the FileChooser, based on what the calling method desires.
        var chooser = new Gtk.FileChooserDialog (title, null, action);
        chooser.add_button (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
        if (action == Gtk.FileChooserAction.OPEN) {
            chooser.add_button (Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
        } else if (action == Gtk.FileChooserAction.SAVE) {
            chooser.add_button (Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
            chooser.set_do_overwrite_confirmation (true);
        }

        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("Text files"));
        filter.add_pattern ("*.txt");
        chooser.add_filter (filter);
        filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("All files"));
        filter.add_pattern ("*");
        chooser.add_filter (filter);

        return chooser;
    }

    /**
     * Display an open dialog and return the selected file. Returned file should exist.
     */
    public File display_open_dialog () {
        var chooser = create_file_chooser (_("Open file"),
                Gtk.FileChooserAction.OPEN);
        File file = null;
        if (chooser.run () == Gtk.ResponseType.ACCEPT)
            file = chooser.get_file ();
        chooser.destroy();
        return file;
    }

    /**
     * Display a save dialog and return the selected file.
     */
    public File display_save_dialog () {
        var chooser = create_file_chooser (_("Save file"),
                Gtk.FileChooserAction.SAVE);
        File file = null;
        if (chooser.run () == Gtk.ResponseType.ACCEPT)
            file = chooser.get_file ();
        chooser.destroy();
        return file;
    }

    private int display_save_confirm () {
        var dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL,
                Gtk.MessageType.WARNING, Gtk.ButtonsType.NONE, "<b>" +
                _("There are unsaved changes. Do you want to save?") + "</b>" +
                "\n\n" + _("If you don't save, changes will be lost forever."));
        dialog.use_markup = true;
        dialog.type_hint = Gdk.WindowTypeHint.DIALOG;
        var dontsave = new Gtk.Button.with_label (_("Don't save"));
        dontsave.show ();
        dialog.add_action_widget (dontsave, Gtk.ResponseType.NO);
        dialog.add_button (Gtk.Stock.SAVE, Gtk.ResponseType.YES);
        dialog.add_button (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
        dialog.set_default_response (Gtk.ResponseType.ACCEPT);
        int response = dialog.run ();
        dialog.destroy();
        return response;
    }

}
