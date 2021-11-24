[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookmovelistview.ui")]
public class Notejot.NotebookMoveListView : View {
    [GtkChild]
    unowned Gtk.SingleSelection selection_model;

    public ObservableList<Notebook>? notebooks { get; set; }
    public Notebook? selected_notebook { get; set;}
    public NotebookViewModel? nbview_model { get; set; }

    construct {
        selection_model.bind_property ("selected", this, "selected-notebook", DEFAULT, (_, from, ref to) => {
            var pos = (uint) from;

            if (pos != Gtk.INVALID_LIST_POSITION)
                to.set_object (selection_model.model.get_item (pos));

            return true;
        });
    }

    public signal void new_notebook_requested ();
}
