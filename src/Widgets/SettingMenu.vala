namespace Notejot {
    public class Widgets.SettingMenu : Object {
        private MainWindow win;
        public Widgets.Note controller;
        public Widgets.NoteMenuPopover nmpopover;
        public Widgets.TrashNoteMenuPopover tnmpopover;

        public SettingMenu (MainWindow win) {
            this.win = win;
            nmpopover = new Widgets.NoteMenuPopover ();

            tnmpopover = new Widgets.TrashNoteMenuPopover ();

            nmpopover.color_button_red.clicked.connect (() => {
                controller.update_theme("#c01c28");
                nmpopover.close ();
            });

            nmpopover.color_button_orange.clicked.connect (() => {
                controller.update_theme("#e66100");
                nmpopover.close ();
            });

            nmpopover.color_button_yellow.clicked.connect (() => {
                controller.update_theme("#f5c211");
                nmpopover.close ();
            });

            nmpopover.color_button_green.clicked.connect (() => {
                controller.update_theme("#2ec27e");
                nmpopover.close ();
            });

            nmpopover.color_button_blue.clicked.connect (() => {
                controller.update_theme("#1c71d8");
                nmpopover.close ();
            });

            nmpopover.color_button_purple.clicked.connect (() => {
                controller.update_theme("#813d9c");
                nmpopover.close ();
            });

            nmpopover.color_button_brown.clicked.connect (() => {
                controller.update_theme("#865e3c");
                nmpopover.close ();
            });

            nmpopover.color_button_reset.clicked.connect (() => {
                controller.update_theme("#ffffff");
                nmpopover.close ();
            });
        }
    }
}
