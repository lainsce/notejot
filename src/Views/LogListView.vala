[GtkTemplate (ui = "/io/github/lainsce/Notejot/loglistview.ui")]
public class Notejot.LogListView : View {
    [GtkChild]
    unowned Gtk.SingleSelection selection_model;

    public ObservableList<Log>? notes { get; set; }
    public Log? selected_note { get; set;}
    public LogViewModel? view_model { get; set; }

    construct {
        selection_model.bind_property ("selected", this, "selected-note", DEFAULT, (_, from, ref to) => {
            var pos = (uint) from;

            if (pos != Gtk.INVALID_LIST_POSITION)
                to.set_object (selection_model.model.get_item (pos));

            return true;
        });
    }

    public signal void new_note_requested ();
}
