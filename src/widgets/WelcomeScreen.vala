namespace Notejot {
    public class WelcomeScreen : He.WelcomeScreen {
        public signal void finished ();

        public WelcomeScreen (Gtk.Window parent) {
            Object (parent: parent);

            this.app_name = "Notejot";

            this.add_row (new He.WelcomeRow ("list-add-symbolic",
                                             _("Create Entries"),
                                             _("Capture your thoughts quickly with a simple, focused editor."),
                                             He.Colors.ORANGE));

            this.add_row (new He.WelcomeRow ("tag-symbolic",
                                             _("Organize with Tags"),
                                             _("Group related notes with colorful tags and icons."),
                                             He.Colors.PURPLE));

            this.add_row (new He.WelcomeRow ("alarm-symbolic",
                                             _("Keep Your Streak"),
                                             _("Enable reminders to build a daily writing habit."),
                                             He.Colors.GREEN));

            this.get_start_button ().clicked.connect (() => {
                this.finished ();
            });
        }

        public static bool should_show (GLib.Settings settings) {
            return settings.get_boolean ("is-first-boot");
        }

        public void mark_completed () {
            NotejotApp.settings.set_boolean ("is-first-boot", false);
        }
    }
}
