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
public class Notejot.TrashViewModel : Object {
    uint timeout_id = 0;

    public ObservableList<Trash> trashs { get; default = new ObservableList<Trash> (); }
    public TrashRepository? repository { private get; construct; }

    public TrashViewModel (TrashRepository repository) {
        Object (repository: repository);
    }

    construct {
        populate_trashs.begin ();
    }

    public void create_new_trash (Note note) {
        var trash = new Trash () {
            title = note.title,
            subtitle = note.subtitle,
            text = note.text,
            notebook = note.notebook,
            color = note.color,
            picture = note.picture,
            pinned = note.pinned
        };

        trashs.add (trash);

        repository.insert_trash (trash);
        save_trashs ();
    }

    public void update_trash (Trash trash) {
        repository.update_trash (trash);

        save_trashs ();
    }

    public void update_trash_color (Trash trash, string color) {
        trash.color = color;

        var style_manager = new StyleManager ();
        style_manager.set_css (color);
        repository.update_trash (trash);

        save_trashs ();
    }

    public void delete_one_trash (Trash trash) {
        trashs.remove (trash);

        repository.delete_trash (trash.id);
        save_trashs ();
    }

    public async void delete_trash (MainWindow win) {
        var dialog = new Gtk.MessageDialog (win, 0, 0, 0, null);
        dialog.modal = true;

        dialog.set_title (_("Clear Trash?"));
        dialog.text = (_("Clearing means the notes in Trash will be permanently lost with no recovery."));

        dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        dialog.add_button (_("Clear"), Gtk.ResponseType.OK);

        dialog.response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.OK:
                    depopulate_trashs.begin ();
                    dialog.close ();
                    break;
                case Gtk.ResponseType.NO:
                    dialog.close ();
                    break;
                case Gtk.ResponseType.CANCEL:
                case Gtk.ResponseType.CLOSE:
                case Gtk.ResponseType.DELETE_EVENT:
                default:
                    dialog.close ();
                    return;
            }
        });

        if (dialog != null) {
            dialog.present ();
            return;
        } else {
            dialog.show ();
        }
    }

    async void populate_trashs () {
        var trashs = yield repository.get_trashs ();
        this.trashs.add_all (trashs);
    }

    async void depopulate_trashs () {
        trashs.remove_all ();

        var rtrashs = yield repository.get_trashs ();
        foreach (var t in rtrashs) {
            repository.delete_trash (t.id);
        }

        save_trashs ();
    }

    void save_trashs () {
        if (timeout_id != 0)
            Source.remove (timeout_id);

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;

            repository.save.begin ();

            return Source.REMOVE;
        });
    }
}
