public class Notejot.NotebookViewModel : Object {
    uint timeout_id = 0;

    public ObservableList<Notebook> notebooks { get; default = new ObservableList<Notebook> (); }
    public NotebookRepository? repository { private get; construct; }

    public NotebookViewModel (NotebookRepository repository) {
        Object (repository: repository);
    }

    construct {
        populate_notebooks.begin ();
    }

    public void create_new_notebook (Notebook notebook) {
        notebooks.add (notebook);

        repository.insert_notebook (notebook);
        save_notebooks ();
    }

    public void update_notebook (Notebook notebook, string nb) {
        repository.update_notebook.begin (notebook, nb);

        save_notebooks ();
    }

    public void delete_notebook (Notebook notebook) {
        notebooks.remove (notebook);

        repository.delete_notebook (notebook.id);
        save_notebooks ();
    }

    async void populate_notebooks () {
        var notebooks = yield repository.get_notebooks ();
        this.notebooks.add_all (notebooks);
    }

    void save_notebooks () {
        if (timeout_id != 0)
            Source.remove (timeout_id);

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;

            repository.save.begin ();

            return Source.REMOVE;
        });
    }
}
