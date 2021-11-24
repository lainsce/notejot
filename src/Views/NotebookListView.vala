[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebooklistview.ui")]
public class Notejot.NotebookListView : View {
    public ObservableList<Notebook>? notebooks { get; set; }
    public NotebookViewModel? nbview_model { get; set; }

    public signal void new_notebook_requested ();
}
