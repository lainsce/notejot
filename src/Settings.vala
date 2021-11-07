[SingleInstance]
public class Notejot.Settings : Object {
    private GLib.Settings settings = new GLib.Settings ("io.github.lainsce.Notejot");
    public bool is_maximized { get; set; }
    public string last_view { get; set; }
    public string font_size { get; set; }
    public int window_w { get; set; }
    public int window_h { get; set; }

    construct {
        settings.bind ("last-view", this, "last-view", DEFAULT);
        settings.bind ("font-size", this, "font-size", DEFAULT);
        settings.bind ("window-w", this, "window-w", DEFAULT);
        settings.bind ("window-h", this, "window-h", DEFAULT);
    }

    public Action create_action (string key) {
        return settings.create_action (key);
    }
}
