namespace Notejot {
    public class Widgets.SettingMenu : Object {
        private MainWindow win;
        public Widgets.Note controller;
        public Widgets.TrashedNote tcontroller;
        public Widgets.TrashNoteMenuPopover tnmpopover;
        public Widgets.NoteTheme nmp;

        public SettingMenu (MainWindow win) {
            this.win = win;

            nmp = new Widgets.NoteTheme ();

            nmp.color_button_red.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#a51d2d");
            });

            nmp.color_button_orange.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#c64600");
            });

            nmp.color_button_yellow.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#e5a50a");
            });

            nmp.color_button_green.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#26a269");
            });

            nmp.color_button_blue.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#1a5fb4");
            });

            nmp.color_button_purple.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#613583");
            });

            nmp.color_button_brown.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#63452c");
            });

            var adwsm = Adw.StyleManager.get_default ();
            if (adwsm.get_color_scheme () != Adw.ColorScheme.PREFER_LIGHT) {
                nmp.color_button_reset.toggled.connect (() => {
                    if (controller != null)
                        controller.update_theme("#000");
                });
            } else {
                nmp.color_button_reset.toggled.connect (() => {
                    if (controller != null)
                        controller.update_theme("#fff");
                });
            }

            tnmpopover = new Widgets.TrashNoteMenuPopover ();
        }
    }
}
