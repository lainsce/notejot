namespace Notejot {
    public class NotejotApp : He.Application {
        private Gtk.CssProvider app_css_provider;
        private ReminderService reminder_service;
        public static Settings settings { get; private set; }
        private const GLib.ActionEntry APP_ENTRIES[] = {
            { "quit", quit },
        };

        // Hold a strong reference so the welcome window isn't GC'ed
        private WelcomeScreen? welcome_screen = null;

        public NotejotApp () {
            Object (application_id : "io.github.lainsce.Notejot");
        }

        static construct {
            settings = new Settings ("io.github.lainsce.Notejot");
        }

        public static int main (string[] args) {
            var app = new NotejotApp ();
            return app.run (args);
        }

        public override void activate () {
            var window = this.active_window;
            if (window == null) {
                window = new Window (this);
            }
            window.present ();

            if (WelcomeScreen.should_show (settings)) {
                this.welcome_screen = new WelcomeScreen (window);

                // Make the Gtk.Application own the welcome window as well
                this.add_window (this.welcome_screen);

                GLib.Idle.add (() => {
                    // It may have been closed quickly; guard against null
                    if (this.welcome_screen != null) {
                        this.welcome_screen.present ();
                    }
                    return false;
                });

                this.welcome_screen.finished.connect (() => {
                    this.welcome_screen.mark_completed ();

                    // Close the welcome window and drop our reference
                    this.welcome_screen.close ();
                    this.welcome_screen = null;

                    this.reminder_service = new ReminderService ();
                    this.reminder_service.start ();
                });
            } else {
                this.reminder_service = new ReminderService ();
                this.reminder_service.start ();
            }
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
            new Window (this);

            // React to dark-mode changes
            this.app_css_provider = new Gtk.CssProvider ();
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), app_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            load_theme_css ();
            var gsettings = Gtk.Settings.get_default ();
            if (gsettings != null) {
                gsettings.notify["gtk-application-prefer-dark-theme"].connect (() => {
                    load_theme_css ();
                });
            }
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
