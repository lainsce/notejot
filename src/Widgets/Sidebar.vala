/*
* Copyright (C) 2017-2020 Lains
*
* This program is free software; you can redistribute it &&/or
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
*/
namespace Notejot {
    public class Widgets.Sidebar : Gtk.Grid {
        private MainWindow win;
        public Hdy.HeaderBar fauxtitlebar;
        public Gtk.Button sidebar_button;
        public Granite.Widgets.SourceList sidebar_categories;
        public Granite.Widgets.SourceList.ExpandableItem notes_category;

        public Sidebar (MainWindow win) {
            this.win = win;

            fauxtitlebar = new Hdy.HeaderBar ();
            fauxtitlebar.set_size_request (199, 45);
            var fauxtitlebar_c = fauxtitlebar.get_style_context ();
            fauxtitlebar_c.add_class ("notejot-side-tbar");
            fauxtitlebar_c.remove_class ("titlebar");
            fauxtitlebar.show_close_button = true;
            fauxtitlebar.has_subtitle = false;

            var sidebar_header = new Gtk.Label (null);
            sidebar_header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            sidebar_header.use_markup = true;
            sidebar_header.halign = Gtk.Align.START;
            sidebar_header.margin_start = 15;
            sidebar_header.margin_top = 6;
            sidebar_header.label = _("VIEW");

            sidebar_categories = new Granite.Widgets.SourceList ();
            sidebar_categories.hexpand = false;
            sidebar_categories.margin_top = 4;
            sidebar_categories.margin_start = sidebar_categories.margin_end = 8;
            notes_category = new Granite.Widgets.SourceList.ExpandableItem ("");
            notes_category.markup = _("NOTES");
            notes_category.tooltip = _("Your notes will appear here.");
            notes_category.set_data("item-name", "projects");
            sidebar_categories.root.add(notes_category);
            sidebar_categories.root.expand_all();

            sidebar_button = new Gtk.Button.with_label (_("Dashboard"));
            sidebar_button.image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.BUTTON);
            sidebar_button.always_show_image = true;
            sidebar_button.margin_start = sidebar_button.margin_end = 9;
            sidebar_button.tooltip_text = (_("Go Back to Notes Overview"));
            sidebar_button.get_style_context ().add_class ("notejot-side-button");

            this.orientation = Gtk.Orientation.VERTICAL;
            this.get_style_context ().add_class ("notejot-column");
            this.attach (fauxtitlebar, 0, 0, 1, 1);
            this.attach (sidebar_header, 0, 1, 1, 1);
            this.attach (sidebar_button, 0, 2, 1, 1);
            this.attach (sidebar_categories, 0, 3, 1, 1);
            this.show_all ();
        }
    }
}