
/*
* Copyright (c) 2023 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
 public class Notejot.NavigationSection : He.Bin {
    private Gtk.SelectionModel _stack_pages;
    private List<Gtk.ToggleButton> _buttons;
    private Gtk.Box main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

    private Gtk.Stack _stack;
    public Gtk.Stack stack {
        get { return this._stack; }
        set {
            if (this._stack == value) return;

            if (this._stack_pages != null) {
                this._stack_pages.selection_changed.disconnect (on_selected_stack_page_changed);
                this._stack_pages.items_changed.disconnect (on_stack_pages_changed);
            }

            this._stack = value;
            this._stack_pages = value.pages;

            this._stack_pages.selection_changed.connect (on_selected_stack_page_changed);
            this._stack_pages.items_changed.connect (on_stack_pages_changed);

            on_stack_pages_changed (0, 0, this._stack_pages.get_n_items ());
        }
    }

    private Gtk.Orientation _orientation;
    public Gtk.Orientation orientation {
        get { return this._orientation; }
        set {
            if (this._orientation == value) return;

            this._orientation = value;
            main_box.orientation = value;
            ((Gtk.BoxLayout)this.get_layout_manager ()).orientation = value;

            if (value == Gtk.Orientation.VERTICAL) {
                main_box.valign = Gtk.Align.CENTER;
                main_box.halign = Gtk.Align.FILL;
                main_box.vexpand = true;
                main_box.hexpand = false;
            } else {
                main_box.valign = Gtk.Align.FILL;
                main_box.halign = Gtk.Align.CENTER;
                main_box.vexpand = false;
                main_box.hexpand = true;
            }
        }
    }

    public NavigationSection () {
        base ();
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BoxLayout));
    }

    construct {
        main_box.add_css_class ("navigation-section");
        main_box.valign = Gtk.Align.CENTER;
        main_box.halign = Gtk.Align.FILL;
        main_box.set_parent (this);

        this.vexpand = true;
        this.hexpand = false;
        this.orientation = Gtk.Orientation.VERTICAL;

        if (this.orientation == Gtk.Orientation.VERTICAL) {
            main_box.valign = Gtk.Align.CENTER;
            main_box.halign = Gtk.Align.FILL;
            this.vexpand = true;
            this.hexpand = false;
        } else {
            main_box.valign = Gtk.Align.FILL;
            main_box.halign = Gtk.Align.CENTER;
            this.vexpand = false;
            this.hexpand = true;
        }
        notify["orientation"].connect (() => {
            if (orientation == Gtk.Orientation.VERTICAL) {
                main_box.valign = Gtk.Align.CENTER;
                main_box.halign = Gtk.Align.FILL;
                this.vexpand = true;
                this.hexpand = false;
            } else {
                main_box.valign = Gtk.Align.FILL;
                main_box.halign = Gtk.Align.CENTER;
                this.vexpand = false;
                this.hexpand = true;
            }
        });
    }

    private void on_stack_pages_changed (uint position, uint removed, uint added) {
        while (removed-- > 0 && this._buttons.nth (position) != null) {
            unowned var button_link = this._buttons.nth (position);

            button_link.data.unparent ();

            unowned var link = button_link;
            button_link = button_link.next;

            this._buttons.delete_link (link);
        }

        while (added-- > 0) {
            unowned var button_link = this._buttons.nth (position);

            var button = new Gtk.ToggleButton () {
                active = this._stack_pages.is_selected (position)
            };
            button.add_css_class ("navigation-section-button");

            var button_child_image = new Gtk.Image ();
            this._stack_pages.get_item (position).bind_property (
                "icon_name",
                button_child_image,
                "icon_name",
                SYNC_CREATE
            );

            var button_child_label = new Gtk.Label ("");
            this._stack_pages.get_item (position).bind_property ("title", button_child_label, "label", SYNC_CREATE);
            var page = (Gtk.StackPage)this._stack_pages.get_item (position);
            if (button.active) {
                this._stack_pages.select_item (position, true);

                if (page.icon_name.contains ("-symbolic")) {
                    page.icon_name = page.icon_name.replace ("-filled", "");
                    page.icon_name = page.icon_name.replace ("-symbolic", "-filled-symbolic");
                } else {
                    page.icon_name = page.icon_name.replace ("-filled", "");
                    page.icon_name = page.icon_name + "-filled-symbolic";
                }
            } else {
                page.icon_name = (page).icon_name.replace ("-filled", "");
            }

            var button_child = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            button_child.append (button_child_image);
            button_child.append (button_child_label);

            button.toggled.connect (() => on_button_toggled (button));
            button.set_child (button_child);
            main_box.append (button);

            if (!this._buttons.is_empty ()) {
                button.set_group ((Gtk.ToggleButton) this._buttons.nth_data (0));
            }

            this._buttons.insert_before (button_link, button);

            position++;
        }
    }

    private void on_selected_stack_page_changed (uint position, uint n_items) {
        unowned var button_link = this._buttons.nth (position);

        while (n_items-- > 0 && button_link != null) {
            button_link.data.active = this._stack_pages.is_selected (position++);
            button_link = button_link.next;
        }
    }

    private void on_button_toggled (Gtk.ToggleButton button) {
        // Don't do anything if this stack has 1 or less items
        if (this._stack_pages.get_n_items () <= 1) {
            return;
        }

        unowned int position = this._buttons.index (button);
        var page = (Gtk.StackPage)this._stack_pages.get_item (position);

        if (button.active) {
            this._stack_pages.select_item (position, true);

            if (page.icon_name.contains ("-symbolic")) {
                page.icon_name = page.icon_name.replace ("-filled", "");
                page.icon_name = page.icon_name.replace ("-symbolic", "-filled-symbolic");
            } else {
                page.icon_name = page.icon_name.replace ("-filled", "");
                page.icon_name = page.icon_name + "-filled-symbolic";
            }
        } else {
            page.icon_name = page.icon_name.replace ("-filled", "");
        }

        this._stack_pages.unselect_item (position);
    }
}