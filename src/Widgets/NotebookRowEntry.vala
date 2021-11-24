[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookrowentry.ui")]
public class Notejot.NotebookRowEntry : Adw.Bin {
    public signal void clicked ();
    public NotebookViewModel? notebooks {get; set;}

    [GtkChild]
    public unowned Gtk.Entry notebook_entry;

    Notebook? _notebook;
    public Notebook? notebook {
        get { return _notebook; }
        set {
            if (value == _notebook)
                return;

            _notebook = value;

            notebook_entry.text = _notebook.title;
        }
    }

    construct {
    }

    [GtkCallback]
    void on_edit_notebook_requested () {

    }
}
