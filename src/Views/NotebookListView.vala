[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebooklistview.ui")]
public class Notejot.NotebookListView : View {
    public ObservableList<Notebook>? notebooks { get; set; }
    public NotebookViewModel? nbview_model { get; set; }
    public NoteViewModel? view_model { get; set; }

    public signal void new_notebook_requested ();
    public signal void notebook_removal_requested (Notebook notebook);

    [GtkCallback]
    public void on_notebook_removal_requested (Notebook notebook) {
        nbview_model.delete_notebook (notebook);
    }
}
