/*
* Copyright (C) 2017-2021 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
public class Notejot.NoteViewModel : Object {
    uint timeout_id = 0;

    public ObservableList<Note> notes { get; default = new ObservableList<Note> (); }
    public NoteRepository? repository { private get; construct; }

    public NoteViewModel (NoteRepository repository) {
        Object (repository: repository);
    }

    construct {
        populate_notes.begin ();
    }

    public void create_new_note (Note? note) {
        var dt = new GLib.DateTime.now_local ();

        var n = new Note () {
            title = _("New Note"),
            subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M")),
            text = _("Type text here…"),
            notebook = _("No Notebook"),
            color = "#797775",
            pinned = false
        };

        if (note == null) {
            notes.add (n);
        } else {
            notes.add (note);
        }

        repository.insert_note (note);
        save_notes ();
    }

    public void restore_trash (Trash trash) {
        var note = new Note () {
            title = trash.title,
            subtitle = trash.subtitle,
            text = trash.text,
            notebook = trash.notebook,
            color = trash.color,
            picture = trash.picture,
            pinned = trash.pinned,
        };

        notes.add (note);

        repository.insert_note (note);
        save_notes ();
    }

    public void update_note (Note note) {
        repository.update_note (note);

        save_notes ();
    }

    public void update_note_color (Note note, string color) {
        note.color = color;

        var style_manager = new StyleManager ();
        style_manager.set_css (color);
        repository.update_note (note);

        save_notes ();
    }

    public void update_notebook (Note note, string nb) {
        repository.update_notebook.begin (note, nb);

        save_notes ();
    }

    public void delete_note (Note note) {
        notes.remove (note);

        repository.delete_note (note.id);
        save_notes ();
    }

    async void populate_notes () {
        var notes = yield repository.get_notes ();
        this.notes.add_all (notes);
    }

    void save_notes () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;

            repository.save.begin ();

            return Source.REMOVE;
        });
    }
}