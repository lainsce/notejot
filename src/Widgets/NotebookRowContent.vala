[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookrowcontent.ui")]
public class Notejot.NotebookRowContent : Adw.Bin {
    public signal void clicked ();
    public NotebookViewModel? notebooks {get; set;}

    [GtkChild]
    public unowned Gtk.Entry notebook_entry;

    Binding? text_binding;

    Notebook? _notebook;
    public Notebook? notebook {
        get { return _notebook; }
        set {
            if (value == _notebook)
                return;

            text_binding?.unbind ();

            _notebook = value;

            text_binding = _notebook?.bind_property (
                "title", notebook_entry, "text", SYNC_CREATE|BIDIRECTIONAL);
        }
    }

    construct {
    }

    [GtkCallback]
    void on_edit_notebook_requested () {
        ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).nbview_model.update_notebook (notebook, notebook_entry.get_text());
    }

    [GtkCallback]
    void on_delete_button_clicked () {
        ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).notebook_removal_requested (notebook);
    }
}
