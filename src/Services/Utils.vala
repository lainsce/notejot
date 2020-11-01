namespace Notejot {
    public class Utils.CleanTrashDialog : Granite.MessageDialog {
        public MainWindow win;

        public CleanTrashDialog (MainWindow win) {
            Object (
                image_icon: new ThemedIcon ("dialog-warning"),
                primary_text: (_("Empty Trash?")),
                secondary_text: (_("Emptying the trash means all the notes in it will be permanently lost."))
            );

            this.win = win;
            this.transient_for = this.win;
            this.modal = true;
        }
        construct {
            var cws = add_button ((_("Cancel")), Gtk.ResponseType.NO);
            var save = add_button ((_("Empty Trash")), Gtk.ResponseType.OK);
            var save_context = save.get_style_context ();
            save_context.add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);


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
        }
    }
}
