[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookrowdelete.ui")]
public class Notejot.NotebookRowDelete : Adw.Bin {
    public signal void clicked ();

    Notebook? _notebook;
    public Notebook? notebook {
        get { return _notebook; }
        set {
            if (value == _notebook)
                return;

            _notebook = value;
        }
    }

    construct {
    }

    [GtkCallback]
    void on_delete_button_clicked () {
        notebook.dispose ();
    }
}
