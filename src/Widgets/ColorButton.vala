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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*/

public class Notejot.Widgets.ColorPicker : ColorButton {
    public signal void color_picked (string color);

    public new string color {
        get {
            return surface.color_;
        } set {
            surface.color_ = value;
            surface.style ();
        }
    }

    private Gtk.Stack colors_grid_stack;
    private Gtk.Popover popover;
    private Gtk.Grid colors_grid;

    public ColorPicker () {
        base ("white");

        colors_grid_stack = new Gtk.Stack ();
        colors_grid_stack.homogeneous = false;

        colors_grid = new Gtk.Grid ();
        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;

        generate_colors ();
        main_grid.attach (colors_grid_stack, 0, 0, 4, 8);

        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (main_grid);

        colors_grid_stack.add_named (colors_grid, "palete");

        this.clicked.connect (() => {
            popover.show_all ();
        });
    }

    public string rgb_to_hex (string rgb) {
        Gdk.RGBA rgba = Gdk.RGBA ();
        rgba.parse (rgb);

        return "#%02x%02x%02x".printf ((int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255));
    }

    public void generate_colors () {
        // Blues
        attach_color ("#51A7FE", 0, 0);

        // Greens
        attach_color ("#70BF40", 1, 0);

        // Yellow
        attach_color ("#F8D229", 2, 0);

        // Orange
        attach_color ("#F68F19", 0, 4);

        // Reds
        attach_color ("#EF5B5B", 1, 4);

        // Purple
        attach_color ("#B569E5", 2, 4);
    }

    private void attach_color (string color, int x, int y) {
        var color_button = new ColorButton (color);
        color_button.set_size_request (48,24);
        color_button.get_style_context ().remove_class ("button");
        color_button.can_focus = false;
        color_button.margin_right = 3;

        if (y % 4 == 3) {
            color_button.margin_bottom = 3;
        }

        colors_grid.attach (color_button, x, y, 1, 1);

        color_button.clicked.connect (() => {
            set_color_smart (color, true);
        });
    }

    private void set_color_smart (string color, bool from_button = false) {
        this.color = color;

        if (from_button) {
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (color);
            color_picked (this.color);
        }
    }

    protected class ColorButton : Gtk.Button {
        protected ColorSurface surface;

        public string color {
            get {
                return surface.color;
            } set {
                surface.color = value;
            }
        }

        public ColorButton (string color) {
            surface = new ColorSurface (color);
            this.add (surface);
        }
    }

    protected class ColorSurface : Gtk.EventBox {
        public string color_ = "null";
        public SourceView buffer;

        public string color {
            get {
                return color_;
            } set {
                if (value != "") {
                    color_ = value;
                    style ();
                }
            }
        }

        public ColorSurface (string color) {
            Object (color:color);
            get_style_context ().add_class ("colored");
            set_size_request (24,24);
            style ();
        }

        public new void style () {
            Utils.ColorUtils.setstyle (this, STYLE_CSS.printf (color_));  
            Utils.ColorUtils.setstyle (buffer, MainWindow.NOTE.printf (color_));   
        }

        private const string STYLE_CSS = """
            .colored {
                background: %s;
            }
        """;
    }
}
