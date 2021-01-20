namespace Notejot {
    public class Widgets.Dialog : Gtk.MessageDialog {
        public MainWindow win;
        private string ltitle;
        private string subtitle;
        private string ok_label;
        private string cancel_label;

        public Dialog (MainWindow win, string ltitle, string subtitle, string cancel_label, string ok_label) {
            this.win = win;
            this.ltitle = ltitle;
            this.subtitle = subtitle;
            this.cancel_label = cancel_label;
            this.ok_label = ok_label;

            transient_for = win;
            modal = true;
            resizable = false;
            title = " ";

            var label_title = new Gtk.Label (ltitle);
            label_title.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);
            label_title.halign = Gtk.Align.START;

            var label_subtitle = new Gtk.Label (subtitle);
            label_subtitle.get_style_context ().add_class (Gtk.STYLE_CLASS_SUBTITLE);
            label_subtitle.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            label_subtitle.halign = Gtk.Align.START;
            label_subtitle.wrap = true;
            label_subtitle.wrap_mode = Pango.WrapMode.WORD;
            label_subtitle.max_width_chars = 36;

            var label_box = new Gtk.Grid ();
            label_box.hexpand = true;
            label_box.vexpand = true;
            label_box.orientation = Gtk.Orientation.VERTICAL;
            label_box.row_spacing = 12;
            label_box.column_spacing = 6;
            label_box.margin_bottom = 12;
            label_box.attach (label_title, 0, 0);
            label_box.attach (label_subtitle, 0, 1);

            var cancel_button = add_button (cancel_label, Gtk.ResponseType.CANCEL);
            cancel_button.is_focus = cancel_button.can_focus = false;
            var ok_button = add_button (ok_label, Gtk.ResponseType.OK);
            ok_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            ok_button.is_focus = ok_button.can_focus = true;

            response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.OK:
                        foreach (Gtk.Widget item in win.trashview.get_children ()) {
                            item.destroy ();
                        }
                        win.tm.save_notes ();
                        this.close ();
                        break;
                    case Gtk.ResponseType.NO:
                        this.close ();
                        break;
                    case Gtk.ResponseType.CANCEL:
                    case Gtk.ResponseType.CLOSE:
                    case Gtk.ResponseType.DELETE_EVENT:
                        this.close ();
                        return;
                    default:
                        assert_not_reached ();
                }
            });

            var grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.hexpand = true;
            grid.vexpand = true;
            grid.attach (label_box, 1, 0);

            this.get_content_area ().add (grid);
            this.get_content_area ().border_width = 0;
            this.get_content_area ().margin_top = 12;
            this.get_content_area ().margin_start = 12;
            this.show_all ();
        }
    }
}
