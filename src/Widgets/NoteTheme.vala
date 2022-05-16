/*
 * Copyright (C) 2017-2022 Lains
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
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/note_theme.ui")]
    public class Widgets.NoteTheme : Gtk.Box {
        [GtkChild]
        public unowned Gtk.Button note_pin_button;
        [GtkChild]
        public unowned Gtk.Button delete_button;
        [GtkChild]
        public unowned Gtk.Button export_button;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_red;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_orange;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_yellow;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_green;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_blue;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_purple;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_brown;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_reset;

        public NoteViewModel ? vm { get; set; }
        public NotebookViewModel ? nvm { get; set; }
        public NoteContentView ? ncv { get; set; }

        public NoteTheme (NoteContentView ? ncv, NoteViewModel ? vm, NotebookViewModel ? nvm) {
            Object (
                vm: vm,
                nvm: nvm,
                ncv: ncv
            );
        }

        [GtkCallback]
        public void action_move_to () {
            var move_to_dialog = new Widgets.MoveToDialog (ncv, nvm, vm);
            move_to_dialog.show ();
            ncv.pop.closed ();
        }
    }
}