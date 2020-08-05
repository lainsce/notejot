/*
* Copyright (c) 2017-2020 Lains
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
*/
namespace Notejot {
    public class Views.MainView : Gtk.Grid {
        public MainWindow win;
        public Views.GridView grid_view;
        public Views.WelcomeView welcome_view;
        public Widgets.Titlebar titlebar;

        public Gtk.Stack stack;

        public MainView (MainWindow win) {
            this.win = win;

            // Main Titlebar
            titlebar = new Widgets.Titlebar (win);
            // Views
            welcome_view = new Views.WelcomeView (win);
            grid_view = new Views.GridView (win);

            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (welcome_view);
            stack.add (grid_view);

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                stack.get_style_context ().add_class ("notejot-stack-dark");
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                stack.get_style_context ().remove_class ("notejot-stack-dark");
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
                }
            });

            var overlay = new Gtk.Overlay ();
            overlay.add_overlay (titlebar);
            overlay.add (stack);

            this.orientation = Gtk.Orientation.VERTICAL;
            this.attach (overlay, 0, 0, 1, 1);
            this.show_all ();
        }
    }
}