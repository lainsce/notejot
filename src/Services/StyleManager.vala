public class Notejot.StyleManager {
    public void set_css (string id, string color) {
        var css_provider = new Gtk.CssProvider();
        string style = @"
            .notejot-badge-$id {
                background: mix(@view_bg_color, $color, 0.55);
                border-radius: 9999px;
            }
            .notejot-header-$id {
                background: mix(@view_bg_color, $color, 0.1);
            }
            .notejot-footer-$id {
                background: mix(@view_bg_color, $color, 0.1);
            }
            .notejot-view-$id text {
                background: mix(@popover_bg_color, $color, 0.02);
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
