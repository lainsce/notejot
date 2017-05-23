/*
* Copyright (c) 2017 Lains
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

public class Application : Gtk.Window {

    private Gtk.HeaderBar header_bar;
    private Gtk.Button new_window_button;
    private Gtk.SourceView view;
    private Gtk.CssProvider provider;
    
    private const string COLOR_PRIMARY = """
    @define-color colorPrimary %s;
        .background,
        .titlebar {
        }
        GtkSourceView {
            background-color: #fff9de;
        }
    """;

    public Application () {
        this.set_position (Gtk.WindowPosition.CENTER);
        this.title = "Notejot";
        this.set_default_size (600, 600);
        this.resizable = false;
        this.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        this.destroy.connect (Gtk.main_quit);
        
        provider.load_from_resource ("com/github/lainsce/notejot/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        new_window_button = new Gtk.Button.from_icon_name ("list-add", Gtk.IconSize.SMALL_TOOLBAR);
        new_window_button.tooltip_text = ("New pad…");
        new_window_button.clicked.connect (() => {var app = new Application (); app.show_all ();});
        
        header_bar = new Gtk.HeaderBar ();
        header_bar.set_title ("Notejot");
        header_bar.show_close_button = true;
        header_bar.pack_end (new_window_button);
        set_titlebar (header_bar);

        Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow (null, null);
        this.add (scroll);

        this.view = new Gtk.SourceView ();
        this.view.wrap_mode = Gtk.WrapMode.WORD;
        this.view.top_margin = 12;
        this.view.left_margin = 12;

        string color_primary = "#fff1b9";

        var provider = new Gtk.CssProvider ();
        try {
            var colored_css = COLOR_PRIMARY.printf (color_primary);
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            critical (e.message);
        }

        scroll.add (view);
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        Application app = new Application ();
        app.show_all ();

        Gtk.main ();
        return 0;
    }
}
