namespace Notejot {
    public class Settings : GLib.Settings {
        public bool dark_mode { get; set; }
        public string last_view { get; set; }
        public string font_size { get; set; }
    
        public Settings () {
            Object (
                schema_id: "io.github.lainsce.Notejot"
            );
            bind ("dark-mode", this, "dark-mode", GLib.SettingsBindFlags.DEFAULT);
            bind ("last-view", this, "last_view", GLib.SettingsBindFlags.DEFAULT);
            bind ("font-size", this, "font_size", GLib.SettingsBindFlags.DEFAULT);
        }
    }
}