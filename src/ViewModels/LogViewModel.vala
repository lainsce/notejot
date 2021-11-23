public class Notejot.LogViewModel : Object {
    uint timeout_id = 0;
    int uid = 0;

    public ObservableList<Log> notes { get; default = new ObservableList<Log> (); }
    public LogRepository? repository { private get; construct; }

    public LogViewModel (LogRepository repository) {
        Object (repository: repository);
    }

    construct {
        populate_notes.begin ();
    }

    public void create_new_note (MainWindow win) {
        var dt = new GLib.DateTime.now_local ();

        uid++;

        var note = new Log () {
            title = _("New Note ") + (@"$uid"),
            subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M")),
            text = "Type text here…",
            notebook = "<i>" + _("No Notebook") + "</i>",
            pinned = "0"
        };

        var adwsm = Adw.StyleManager.get_default ();
        if (adwsm.get_color_scheme () != Adw.ColorScheme.PREFER_LIGHT) {
            note.color = "#151515";
        } else {
            note.color = "#fff";
        }

        notes.add (note);

        repository.insert_note (note);
        save_notes ();
    }

    public void update_note (Log note) {
        repository.update_note (note);

        save_notes ();
    }

    public void update_note_color (Log note, string color) {
        repository.update_note_color.begin (note, color);

        save_notes ();
    }

    public void update_notebook (Log note, string nb) {
        repository.update_notebook.begin (note, nb);

        save_notes ();
    }

    public void delete_note (Log note, MainWindow win) {
        var dialog = new Gtk.MessageDialog (win, 0, 0, 0, null);
        dialog.modal = true;

        dialog.set_title (_("Delete This Note?"));
        dialog.text = (_("Deleting means the note will be permanently lost with no recovery."));

        dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        dialog.add_button (_("Delete"), Gtk.ResponseType.OK);

        dialog.response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.OK:
                    notes.remove (note);

                    repository.delete_note (note.id);
                    save_notes ();
                    dialog.close ();
                    break;
                case Gtk.ResponseType.NO:
                    dialog.close ();
                    break;
                case Gtk.ResponseType.CANCEL:
                case Gtk.ResponseType.CLOSE:
                case Gtk.ResponseType.DELETE_EVENT:
                    dialog.close ();
                    return;
                default:
                    assert_not_reached ();
            }
        });

        if (dialog != null) {
            dialog.present ();
            return;
        } else {
            dialog.show ();
        }
    }

    async void populate_notes () {
        var notes = yield repository.get_notes ();
        this.notes.add_all (notes);
    }

    void save_notes () {
        if (timeout_id != 0)
            Source.remove (timeout_id);

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;

            repository.save.begin ();

            return Source.REMOVE;
        });
    }
}
