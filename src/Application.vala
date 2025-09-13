namespace Notejot {
    public class NotejotApp : He.Application {
        private Gtk.CssProvider app_css_provider;
        private ReminderService reminder_service;
        public static Settings settings { get; private set; }
        private const GLib.ActionEntry APP_ENTRIES[] = {
            { "quit", quit },
        };

        public NotejotApp () {
            Object (application_id: "io.github.lainsce.Notejot");
        }

        static construct {
            settings = new Settings ("io.github.lainsce.Notejot");
        }

        public static int main (string[] args) {
            var app = new NotejotApp ();
            return app.run (args);
        }

        public override void activate () {
            this.active_window?.present ();
        }

        public override void startup () {
            Gdk.RGBA accent_color = {};
            accent_color.parse ("#ffd54f");

            Gdk.RGBA secondary_color = {};
            secondary_color.parse ("#8a8a8e");

            Gdk.RGBA tertiary_color = {};
            tertiary_color.parse ("#32ade6");

            default_accent_color = He.from_gdk_rgba (accent_color);
            default_secondary_color = He.from_gdk_rgba (secondary_color);
            default_tertiary_color = He.from_gdk_rgba (tertiary_color);
            override_accent_color = true;

            resource_base_path = "/io/github/lainsce/Notejot";

            base.startup ();

            add_action_entries (APP_ENTRIES, this);

            // React to dark-mode changes
            this.app_css_provider = new Gtk.CssProvider ();
            var settings = Gtk.Settings.get_default ();
            if (settings != null) {
                settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
                    load_theme_css ();
                });
            }

            new Window (this);
            this.reminder_service = new ReminderService ();
            this.reminder_service.start ();
        }

        private void load_theme_css () {
            bool prefer_dark = false;
            var settings = Gtk.Settings.get_default ();
            if (settings != null) {
                GLib.Value val = GLib.Value (typeof (bool));
                settings.get_property ("gtk-application-prefer-dark-theme", ref val);
                prefer_dark = (bool) val;
            }
            if (prefer_dark) {
                this.app_css_provider.load_from_resource ("/io/github/lainsce/Notejot/style_dark.css");
            } else {
                this.app_css_provider.load_from_resource ("/io/github/lainsce/Notejot/style.css");
            }
        }
    }
}
