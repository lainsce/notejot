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
        public unowned He.Button note_pin_button;
        [GtkChild]
        public unowned He.Button export_button;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_red;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_yellow;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_green;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_blue;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_purple;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_reset;
    }
}
