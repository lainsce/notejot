namespace Notejot {
    public class Widgets.SettingMenu : Gtk.MenuButton {
        private MainWindow win;
        public Widgets.Note controller;

        public SettingMenu (MainWindow win) {
            this.win = win;

            var color_button_red = new Gtk.RadioButton (null) {
                tooltip_text = _("Red")
            };
            color_button_red.get_style_context ().add_class ("color-button");
            color_button_red.get_style_context ().add_class ("color-red");

            var color_button_orange = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Orange")
            };
            color_button_orange.get_style_context ().add_class ("color-button");
            color_button_orange.get_style_context ().add_class ("color-orange");

            var color_button_yellow = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Yellow")
            };
            color_button_yellow.get_style_context ().add_class ("color-button");
            color_button_yellow.get_style_context ().add_class ("color-yellow");

            var color_button_green = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Green")
            };
            color_button_green.get_style_context ().add_class ("color-button");
            color_button_green.get_style_context ().add_class ("color-green");

            var color_button_blue = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Blue")
            };
            color_button_blue.get_style_context ().add_class ("color-button");
            color_button_blue.get_style_context ().add_class ("color-blue");

            var color_button_purple = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Purple")
            };
            color_button_purple.get_style_context ().add_class ("color-button");
            color_button_purple.get_style_context ().add_class ("color-purple");

            var color_button_brown = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Brown")
            };
            color_button_brown.get_style_context ().add_class ("color-button");
            color_button_brown.get_style_context ().add_class ("color-brown");

            var color_button_reset = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("No Color")
            };
            color_button_reset.get_style_context ().add_class ("color-button");
            color_button_reset.get_style_context ().add_class ("color-reset");

            var color_button_box = new Gtk.Grid () {
                margin_start = 12,
                margin_end = 12,
                column_spacing = 6,
                row_spacing = 6
            };
            color_button_box.attach (color_button_red, 0, 0);
            color_button_box.attach (color_button_orange, 1, 0);
            color_button_box.attach (color_button_yellow, 2, 0);
            color_button_box.attach (color_button_green, 3, 0);
            color_button_box.attach (color_button_blue, 0, 1);
            color_button_box.attach (color_button_purple, 1, 1);
            color_button_box.attach (color_button_brown, 2, 1);
            color_button_box.attach (color_button_reset, 3, 1);

            var delete_note_button = new Gtk.ModelButton ();
            delete_note_button.label = (_("Move to Trash"));

			delete_note_button.clicked.connect (() => {
			    win.trashview.new_taskbox (win, controller.title, controller.subtitle, controller.text, controller.color);
                win.main_stack.set_visible_child (win.empty_state);
                controller.destroy_item ();
                win.tm.save_notes ();
                win.settingmenu.visible = false;
            });

            color_button_red.clicked.connect (() => {
                controller.update_theme("#f66151");
            });

            color_button_orange.clicked.connect (() => {
                controller.update_theme("#ffbe6f");
            });

            color_button_yellow.clicked.connect (() => {
                controller.update_theme("#f9f06b");
            });

            color_button_green.clicked.connect (() => {
                controller.update_theme("#8ff0a4");
            });

            color_button_blue.clicked.connect (() => {
                controller.update_theme("#99c1f1");
            });

            color_button_purple.clicked.connect (() => {
                controller.update_theme("#dc8add");
            });

            color_button_brown.clicked.connect (() => {
                controller.update_theme("#cdab8f");
            });

            color_button_reset.clicked.connect (() => {
                controller.update_theme("#ffffff");
            });

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 6;
            grid.row_spacing = 6;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (color_button_box, 0, 1, 1, 1);
            grid.attach (sep, 0, 2, 1, 1);
            grid.attach (delete_note_button, 0, 3, 1, 1);
            grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (grid);

            this.has_tooltip = true;
            this.tooltip_text = (_("Settings"));
            this.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.popover = popover;
            this.halign = Gtk.Align.END;
            this.show_all ();
        }
    }
}
