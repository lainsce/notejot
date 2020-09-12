namespace Notejot {
    public class Widgets.SettingMenu : Gtk.MenuButton {
        private MainWindow win;
        public Widgets.TaskBox? taskbox;

        public SettingMenu (MainWindow win, Widgets.TaskBox taskbox) {
            this.win = win;
            this.taskbox = taskbox;

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

            var color_button_violet = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Violet")
            };
            color_button_violet.get_style_context ().add_class ("color-button");
            color_button_violet.get_style_context ().add_class ("color-violet");

            var color_button_neutral = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Gray")
            };
            color_button_neutral.get_style_context ().add_class ("color-button");
            color_button_neutral.get_style_context ().add_class ("color-neutral");

            var color_button_box = new Gtk.Grid () {
                margin_start = 12,
                margin_end = 12,
                column_spacing = 6
            };
            color_button_box.add (color_button_red);
            color_button_box.add (color_button_orange);
            color_button_box.add (color_button_yellow);
            color_button_box.add (color_button_green);
            color_button_box.add (color_button_blue);
            color_button_box.add (color_button_violet);
            color_button_box.add (color_button_neutral);

            var color_button_label = new Granite.HeaderLabel (_("Note Badge Color")) {
                margin_start = 6,
                margin_end = 12
            };

            var delete_note_button = new Gtk.Button () {
                margin = 3,
                halign = Gtk.Align.END
            };
            delete_note_button.label = (_("Delete Note"));
            delete_note_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            delete_note_button.get_style_context ().add_class ("destructive-text");

			delete_note_button.clicked.connect (() => {
                if (win.gridview.get_children () == null) {
                    if (win.stack.get_visible_child_name () == "grid") {
                        win.stack.set_visible_child (win.welcome_view);
                    }
                }
                win.trashview.new_taskbox (win, taskbox.title, taskbox.contents, taskbox.color);
                taskbox.get_parent ().destroy ();
                taskbox.sidebaritem.destroy_item ();
                taskbox.taskline.destroy ();
                win.tm.save_notes.begin ();
            });
            
            color_button_red.clicked.connect (() => {
                taskbox.update_theme("#F3ACAA");
            });

            color_button_orange.clicked.connect (() => {
                taskbox.update_theme("#FFC78B");
            });

            color_button_yellow.clicked.connect (() => {
                taskbox.update_theme("#FCF092");
            });

            color_button_green.clicked.connect (() => {
                taskbox.update_theme("#B1FBA2");
            });

            color_button_blue.clicked.connect (() => {
                taskbox.update_theme("#B8EFFA");
            });

            color_button_violet.clicked.connect (() => {
                taskbox.update_theme("#C0C0F5");
            });

            color_button_neutral.clicked.connect (() => {
                taskbox.update_theme("#DADADA");
            });

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 6;
            grid.row_spacing = 6;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (color_button_label, 0, 0, 1, 1);
            grid.attach (color_button_box, 0, 1, 1, 1);
            grid.attach (delete_note_button, 0, 2, 1, 1);
            grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (grid);

            this.has_tooltip = true;
            this.tooltip_text = (_("Settings"));
            this.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.popover = popover;
            this.halign = Gtk.Align.END;
        }
    }
}