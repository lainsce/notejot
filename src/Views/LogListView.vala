[GtkTemplate (ui = "/io/github/lainsce/Notejot/loglistview.ui")]
public class Notejot.LogListView : View {
    [GtkChild]
    unowned Gtk.SingleSelection selection_model;

    public bool is_modified {get; set; default = false;}
    public string search_text = "";
    public string selected_notebook = "";
    public int last_uid;

    public ObservableList<Log>? notes { get; set; }
    public Log? selected_note { get; set; }

    construct {
        selection_model.bind_property ("selected", this, "selected-note", DEFAULT, (_, from, ref to) => {
            var position = (uint) from;

            if (position != Gtk.INVALID_LIST_POSITION)
                to.set_object (selection_model.model.get_item (position));
                display_note_requested ();

            return true;
        });
    }

    public signal void new_note_requested ();
    public signal void display_note_requested ();
}
