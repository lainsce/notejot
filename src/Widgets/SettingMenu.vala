namespace Notejot {
    public class Widgets.SettingMenu : Gtk.MenuButton {
        private MainWindow win;
        public Widgets.Note controller;

        public SettingMenu (MainWindow win) {
            this.win = win;
            var vpopover = new Widgets.NoteMenuPopover ();

            vpopover.delete_note_button.clicked.connect (() => {
                var tlog = new Log ();
                tlog.title = controller.log.title;
                tlog.subtitle = controller.log.subtitle;
                tlog.text = controller.log.text;
                tlog.color = controller.log.color;
			    win.trashstore.append (tlog);

                win.main_stack.set_visible_child (win.empty_state);
                var row = win.main_stack.get_child_by_name ("textfield-%d".printf(controller.uid));
                win.main_stack.remove (row);

                uint pos;
                win.notestore.find (controller.log, out pos);
                win.notestore.remove (pos);
                win.settingmenu.visible = false;
            });

            vpopover.color_button_red.clicked.connect (() => {
                controller.update_theme("#f66151");
            });

            vpopover.color_button_orange.clicked.connect (() => {
                controller.update_theme("#ffbe6f");
            });

            vpopover.color_button_yellow.clicked.connect (() => {
                controller.update_theme("#f9f06b");
            });

            vpopover.color_button_green.clicked.connect (() => {
                controller.update_theme("#8ff0a4");
            });

            vpopover.color_button_blue.clicked.connect (() => {
                controller.update_theme("#99c1f1");
            });

            vpopover.color_button_purple.clicked.connect (() => {
                controller.update_theme("#dc8add");
            });

            vpopover.color_button_brown.clicked.connect (() => {
                controller.update_theme("#cdab8f");
            });

            vpopover.color_button_reset.clicked.connect (() => {
                controller.update_theme("#ffffff");
            });

            this.has_tooltip = true;
            this.tooltip_text = (_("Note Settings"));
            this.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.popover = vpopover;
            this.halign = Gtk.Align.END;
            this.show_all ();
        }
    }
}
