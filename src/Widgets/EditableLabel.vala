/*
* Copyright (c) 2017-2021 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
* Co-authored by: Corentin Noël <corentin@elementary.io>
*
*/
namespace Notejot {
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/editable_label.ui")]
    public class Widgets.EditableLabel : Gtk.EventBox {
        private MainWindow win;
        public signal void changed (string new_title);

        [GtkChild]
        public Gtk.Label title;

        [GtkChild]
        private Gtk.Entry entry;

        [GtkChild]
        private Gtk.Stack stack;

        [GtkChild]
        private Gtk.Box grid;

        [GtkChild]
        private Gtk.Button edit_button;

        [GtkChild]
        private Gtk.Revealer button_revealer;

        public string text {
            get {
                return title.label;
            }

            set {
                title.label = value;
            }
        }

        private bool editing {
            set {
                if (value) {
                    entry.text = title.label;
                    stack.set_visible_child (entry);
                    entry.grab_focus ();
                } else {
                    if (entry.text.strip () != "" && title.label != entry.text) {
                        title.label = entry.text;
                        changed (entry.text);
                    }

                    stack.set_visible_child (grid);
                }
            }
        }

        public EditableLabel (MainWindow win, string? title_name) {
            this.win = win;
            events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
            events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
            events |= Gdk.EventMask.BUTTON_PRESS_MASK;

            title.set_label (title_name);

            show_all ();

            enter_notify_event.connect ((event) => {
                if (event.detail != Gdk.NotifyType.INFERIOR) {
                    button_revealer.set_reveal_child (true);
                    event.window.set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default(), "text"));
                }

                return false;
            });

            leave_notify_event.connect ((event) => {
                if (event.detail != Gdk.NotifyType.INFERIOR) {
                    button_revealer.set_reveal_child (false);
                }
                event.window.set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default(), "default"));

                return false;
            });

            button_release_event.connect ((event) => {
                editing = true;
                return false;
            });

            edit_button.clicked.connect (() => {
                editing = true;
            });

            entry.activate.connect (() => {
                editing = false;
            });

            entry.focus_out_event.connect ((event) => {
                editing = false;
                return false;
            });

            entry.icon_release.connect ((p0, p1) => {
                if (p0 == Gtk.EntryIconPosition.SECONDARY) {
                    editing = false;
                }
            });
        }
    }
}
