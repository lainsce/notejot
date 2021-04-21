namespace Notejot {
    public class Widgets.SettingMenu : Gtk.MenuButton {
        private MainWindow win;
        public Widgets.Note controller;

        public SettingMenu (MainWindow win) {
            this.win = win;
            var popover = new Widgets.NoteMenuPopover ();

            popover.delete_note_button.clicked.connect (() => {
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

            this.has_tooltip = true;
            this.tooltip_text = (_("Note Settings"));
            this.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.popover = popover;
            this.halign = Gtk.Align.END;
            this.get_style_context ().add_class ("header-button");
            this.show_all ();
        }
    }
}
