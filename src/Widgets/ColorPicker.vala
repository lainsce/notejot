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

    private ColorButton color1;

    public ColorPicker () {
        base ("#FFF394");

        colors_grid_stack = new Gtk.Stack ();
        colors_grid_stack.homogeneous = true;

        colors_grid = new Gtk.Grid ();
        var main_grid = new Gtk.Grid ();
        main_grid.margin_left = 6;
        main_grid.margin_bottom = 6;

        generate_colors ();

        var gradient_grid = new Gtk.Grid ();
        gradient_grid.row_spacing = 6;

        main_grid.attach (colors_grid_stack, 0, 0, 4, 1);

        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (main_grid);

        colors_grid_stack.add_named (colors_grid, "palete");

        this.clicked.connect (() => {
            colors_grid_stack.set_visible_child_name ("palete");
            popover.show_all ();
        });
    }

    public string rgb_to_hex (string rgb) {
        Gdk.RGBA rgba = Gdk.RGBA ();
        rgba.parse (rgb);

        return "#%02x%02x%02x".printf ((int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255));
    }

    public void generate_colors () {
        // Red
        attach_color ("#FF8C82", 0, 0);

        // ORANGE
        attach_color ("#FFC27D", 1, 0);

        // Yellow
        attach_color ("#FFF394", 2, 0);

        // Green
        attach_color ("#D1FF82", 0, 5);

        // Blue
        attach_color ("#8CD5FF", 1, 5);

        // Purple
        attach_color ("#E29FFC", 2, 5);
    }

    private void attach_color (string color, int x, int y) {
        var color_button = new ColorButton (color);
        color_button.set_size_request (48,24);
        color_button.get_style_context ().remove_class ("button");
        color_button.can_focus = false;
        color_button.margin_right = 6;
        color_button.margin_top = 6;

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
        public string color_ = "none";

        public string color {
            get {
                return color_;
            } set {
                if (value != "") {
                    var settings = AppSettings.get_default ();
                    color_ = value;
                    settings.last_note_color = color_;
                    this.style ();
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
            var settings = AppSettings.get_default ();
            settings.last_note_color = color_;
            Utils.ColorUtils.set_style (NOTE_CSS.printf (settings.last_note_color));
            Utils.ColorUtils.set_style_widget (this, STYLE_CSS.printf (color_));
        }

        public const string STYLE_CSS = """
            .colored {
                background: %s;
            }
        """;

        public const string NOTE_CSS = """
            @define-color colorPrimary %s;

            .notejot-note {
                background-color: @colorPrimary;
            }

            .notejot-note:selected {
                color: @colorPrimary;
            }

            .notejot-window {
                background-color: @colorPrimary;
            }
        """;
    }
}
