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
            text = ltitle;
            secondary_text = subtitle;

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
            this.show_all ();
        }
    }
}
