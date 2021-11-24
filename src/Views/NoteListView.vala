[GtkTemplate (ui = "/io/github/lainsce/Notejot/notelistview.ui")]
public class Notejot.NoteListView : View {
    [GtkChild]
    unowned Gtk.SingleSelection selection_model;

    public ObservableList<Note>? notes { get; set; }
    public Note? selected_note { get; set;}
    public NoteViewModel? view_model { get; set; }

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
