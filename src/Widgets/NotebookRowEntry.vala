[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookrowentry.ui")]
public class Notejot.NotebookRowEntry : Adw.Bin {
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
        notebooks.update_notebook (notebook, notebook_entry.get_text());
    }
}
