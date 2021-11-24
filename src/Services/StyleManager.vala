public class Notejot.StyleManager {
    public void set_css (string id, string color) {
        var css_provider = new Gtk.CssProvider();
        string style = @"
            .notejot-badge {
                background: mix(@view_bg_color, @note_color, 0.55);
                border-radius: 9999px;
            }
            .notejot-header {
                background: mix(@view_bg_color, @note_color, 0.1);
            }
            .notejot-footer {
                background: mix(@view_bg_color, @note_color, 0.1);
            }
            .notejot-view text {
                background: mix(@popover_bg_color, @note_color, 0.02);
            }
        ";
        css_provider.load_from_data(style.data);
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}
