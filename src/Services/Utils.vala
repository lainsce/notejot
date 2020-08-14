namespace Notejot {
    public class Utils.Dialog : Granite.MessageDialog {
        public MainWindow win;
        private Widgets.TaskBox? tb;

        public Dialog (MainWindow win, Widgets.TaskBox tb) {
            Object (
                image_icon: new ThemedIcon ("dialog-warning"),
                primary_text: (_("Delete this Note?")),
                secondary_text: (_("Deleting this note means its contents will be permeanently lost."))
            );
            
            this.win = win;
            this.tb = tb;
            this.transient_for = this.win;
            this.modal = true;
        }
        construct {
            var cws = add_button ((_("Cancel")), Gtk.ResponseType.NO);
            var save = add_button ((_("Delete Note")), Gtk.ResponseType.OK);
            var save_context = save.get_style_context ();
            save_context.add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            

            response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.OK:
                        if (win.flowgrid != null && win.notes_category != null){
                            if (win.flowgrid.get_children () == null) {
                                if (win.stack.get_visible_child () == win.grid_view) {
                                    win.stack.set_visible_child (win.welcome_view);
                                }
                            }
                            tb.get_parent ().destroy ();
                            tb.sidebaritem.destroy_item ();
                            tb.taskline.destroy ();
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