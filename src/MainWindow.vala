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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
public class Notejot.MainWindow : Gtk.ApplicationWindow {
    private Gtk.HeaderBar header_bar;
    private Gtk.Button save_button;
    private Gtk.SourceView view;
    private Gtk.ScrolledWindow scroll;

    GLib.File? file;
	Gtk.SourceBuffer buffer;

    private const string COLORS = """
    @define-color colorPrimary %s;
        .background,
        .titlebar {
        }
        GtkSourceView {
            font-size: 12;
        }
    """;

    public MainWindow (Gtk.Application application) {
        Object (application: application,
                icon_name: "com.github.lainsce.notejot",
                resizable: false,
                title: ("Notejot"),
                height_request: 500,
                width_request: 500);
    }

    construct {
        save_button = new Gtk.Button.from_icon_name ("document-save-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        save_button.tooltip_text = ("Save pad…");
        save_button.clicked.connect (() => {
            // TODO: Saving
        });

        header_bar = new Gtk.HeaderBar ();
        header_bar.set_title ("Notejot");
        header_bar.show_close_button = true;
        header_bar.pack_end (save_button);
        set_titlebar (header_bar);

        scroll = new Gtk.ScrolledWindow (null, null);
        this.add (scroll);
        buffer = new Gtk.SourceBuffer (null);
		view = new Gtk.SourceView.with_buffer (buffer);
		view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        view.top_margin = 12;
        view.left_margin = 12;
        view.bottom_margin = 12;
        view.right_margin = 12;
        scroll.add (view);

        string color_primary = "#fff1b9";
        var provider = new Gtk.CssProvider ();
            try {
                var colored_css = COLORS.printf (color_primary);
                provider.load_from_data (colored_css, colored_css.length);

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                critical (e.message);
            }
    }
}
