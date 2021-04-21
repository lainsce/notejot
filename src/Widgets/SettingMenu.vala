namespace Notejot {
    public class Widgets.SettingMenu : Object {
        private MainWindow win;
        public Widgets.Note controller;
        public Widgets.NoteMenuPopover popover;

        public SettingMenu (MainWindow win) {
            this.win = win;
            popover = new Widgets.NoteMenuPopover ();

            popover.color_button_red.clicked.connect (() => {
                controller.update_theme("#c01c28");
            });

            popover.color_button_orange.clicked.connect (() => {
                controller.update_theme("#e66100");
            });

            popover.color_button_yellow.clicked.connect (() => {
                controller.update_theme("#f5c211");
            });

            popover.color_button_green.clicked.connect (() => {
                controller.update_theme("#2ec27e");
            });

            popover.color_button_blue.clicked.connect (() => {
                controller.update_theme("#1c71d8");
            });

            popover.color_button_purple.clicked.connect (() => {
                controller.update_theme("#813d9c");
            });

            popover.color_button_brown.clicked.connect (() => {
                controller.update_theme("#865e3c");
            });

            popover.color_button_reset.clicked.connect (() => {
                controller.update_theme("#ffffff");
            });
        }
    }
}
