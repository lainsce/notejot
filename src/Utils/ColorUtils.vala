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
public class Notejot.Utils.ColorUtils {
    public static void set_style (string css) {
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (css, css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }

    public static void set_style_widget (Gtk.Widget widget, string css) {
    try {
        var provider = new Gtk.CssProvider ();
        var context = widget.get_style_context ();

        provider.load_from_data (css, css.length);

        context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    } catch (Error e) {
        warning ("Style error: %s", e.message);
        stderr.printf ("%s %s\n", widget.name, css);
    }
}
}
