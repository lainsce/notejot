namespace Notejot {
    public class Widgets.SettingMenu : Object {
        public Log? controller;
        public LogViewModel? vm;
        public Widgets.NoteTheme nmp;

        public SettingMenu (LogViewModel? vm) {
            this.vm = vm;

            nmp = new Widgets.NoteTheme ();

            nmp.color_button_red.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#a51d2d");
            });

            nmp.color_button_orange.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#c64600");
            });

            nmp.color_button_yellow.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#e5a50a");
            });

            nmp.color_button_green.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#26a269");
            });

            nmp.color_button_blue.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#1a5fb4");
            });

            nmp.color_button_purple.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#613583");
            });

            nmp.color_button_brown.toggled.connect (() => {
                if (controller != null)
                    vm.update_note_color (controller, "#63452c");
            });

            var adwsm = Adw.StyleManager.get_default ();
            if (adwsm.get_color_scheme () != Adw.ColorScheme.PREFER_LIGHT) {
                nmp.color_button_reset.toggled.connect (() => {
                    if (controller != null)
                        vm.update_note_color (controller, "#151515");
                });
            } else {
                nmp.color_button_reset.toggled.connect (() => {
                    if (controller != null)
                        vm.update_note_color (controller, "#fff");
                });
            }
        }
    }
}
