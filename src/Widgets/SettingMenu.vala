namespace Notejot {
    public class Widgets.SettingMenu : Object {
        private MainWindow win;
        public Widgets.Note controller;
        public Widgets.PinnedNote pcontroller;
        public Widgets.TrashedNote tcontroller;
        public Widgets.TrashNoteMenuPopover tnmpopover;
        public Widgets.NoteTheme nmp;

        public SettingMenu (MainWindow win) {
            this.win = win;

            nmp = new Widgets.NoteTheme ();

            nmp.color_button_red.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#c01c28");
                if (pcontroller != null)
                    pcontroller.update_theme("#c01c28");
            });

            nmp.color_button_orange.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#e66100");
                if (pcontroller != null)
                    pcontroller.update_theme("#e66100");
            });

            nmp.color_button_yellow.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#f5c211");
                if (pcontroller != null)
                    pcontroller.update_theme("#f5c211");
            });

            nmp.color_button_green.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#2ec27e");
                if (pcontroller != null)
                    pcontroller.update_theme("#2ec27e");
            });

            nmp.color_button_blue.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#1c71d8");
                if (pcontroller != null)
                    pcontroller.update_theme("#1c71d8");
            });

            nmp.color_button_purple.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#813d9c");
                if (pcontroller != null)
                    pcontroller.update_theme("#813d9c");
            });

            nmp.color_button_brown.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#865e3c");
                if (pcontroller != null)
                    pcontroller.update_theme("#865e3c");
            });

            nmp.color_button_reset.toggled.connect (() => {
                if (controller != null)
                    controller.update_theme("#ffffff");
                if (pcontroller != null)
                    pcontroller.update_theme("#ffffff");
            });

            tnmpopover = new Widgets.TrashNoteMenuPopover ();
        }
    }
}
