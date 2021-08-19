namespace Notejot {
    public class Settings : GLib.Settings {
        public bool dark_mode { get; set; }
        public bool is_maximized { get; set; }
        public string last_view { get; set; }
        public string font_size { get; set; }
        public int window_w { get; set; }
        public int window_h { get; set; }
    
        public Settings () {
            Object (
                schema_id: "io.github.lainsce.Notejot"
            );

            bind ("dark-mode", this, "dark-mode", GLib.SettingsBindFlags.DEFAULT);
            bind ("last-view", this, "last-view", GLib.SettingsBindFlags.DEFAULT);
            bind ("font-size", this, "font-size", GLib.SettingsBindFlags.DEFAULT);
            bind ("window-w", this, "window-w", GLib.SettingsBindFlags.DEFAULT);
            bind ("window-h", this, "window-h", GLib.SettingsBindFlags.DEFAULT);
        }
    }
}