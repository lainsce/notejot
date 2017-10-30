namespace Notejot {
    private class ColorWidget : Gtk.MenuItem {
        private new bool has_focus;
        private int height;
        public signal void color_changed (int ncolor);

        public ColorWidget () {
            set_size_request (200, 30);
            height = 30;

            button_press_event.connect (button_pressed_cb);
            draw.connect (on_draw);

            select.connect (() => {
                has_focus = true;
            });

            deselect.connect (() => {
                has_focus = false;
            });
        }

        private bool button_pressed_cb (Gdk.EventButton event) {
            determine_button_pressed_event (event);
            return true;
        }

        private void determine_button_pressed_event (Gdk.EventButton event) {
            int i;
            int btnw = 15;
            int btnh = 15;
            int y0 = (height - btnh) / 2;
            int x0 = btnw + 6;

            if (event.y >= y0 && event.y <= y0+btnh) {
                for (i=1; i<=9; i++) {
                    if (event.x >= x0 * i && event.x <= x0 * i + btnw + 6) {
                        color_changed (i);
                        break;
                    }
                }
            }
        }

        protected bool on_draw (Cairo.Context cr) {
            int i;
            int btnw = 15;
            int btnh = 15;
            int y0 = (height - btnh) / 2;
            int x0 = btnw + 6;

            for (i=1; i<=9; i++) {
                DrawRoundedRectangle (cr,x0 * i + 6, y0, btnw, btnh, "stroke", i + 1);
                DrawRoundedRectangle (cr,x0 * i + 6, y0, btnw, btnh, "fill", i + 1);
            }

            return true;
        }

        /*
         * Create a rounded rectangle using the Bezier curve.
         * Adapted from http://cairographics.org/cookbook/roundedrectangles/
         */
        private void DrawRoundedRectangle (Cairo.Context cr, int x, int y, int w, int h, string style, int color) {
            int radius_x=2;
            int radius_y=2;
            double ARC_TO_BEZIER = 0.55228475;

            if (radius_x > w - radius_x)
                radius_x = w / 2;

            if (radius_y > h - radius_y)
                radius_y = h / 2;

            /* approximate (quite close) the arc using a bezier curve */
            double ca = ARC_TO_BEZIER * radius_x;
            double cb = ARC_TO_BEZIER * radius_y;

            cr.new_path ();
            cr.set_line_width (0.7);
            cr.set_tolerance (0.1);
            cr.move_to (x + radius_x, y);
            cr.rel_line_to (w - 2 * radius_x, 0.0);
            cr.rel_curve_to (ca, 0.0, radius_x, cb, radius_x, radius_y);
            cr.rel_line_to (0, h - 2 * radius_y);
            cr.rel_curve_to (0.0, cb, ca - radius_x, radius_y, -radius_x, radius_y);
            cr.rel_line_to (-w + 2 * radius_x, 0);
            cr.rel_curve_to (-ca, 0, -radius_x, -cb, -radius_x, -radius_y);
            cr.rel_line_to (0, -h + 2 * radius_y);
            cr.rel_curve_to (0.0, -cb, radius_x - ca, -radius_y, radius_x, -radius_y);

            switch (style) {
            default:
            case "fill":
                Gdk.RGBA rgba = Gdk.RGBA ();
                rgba.parse (MainWindow.value_color[color]);
                Gdk.cairo_set_source_rgba (cr, rgba);
                cr.fill ();
                break;
            case "stroke":
                cr.set_source_rgba (0,0,0,0.5);
                cr.stroke ();
                break;
            }

            cr.close_path ();
        }
    }
}
