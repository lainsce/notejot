public class Notejot.LogRepository : Object {
    const string FILENAME = "saved_notes.json";

    Queue<Log> insert_queue = new Queue<Log> ();
    public Queue<Log> update_queue = new Queue<Log> ();
    Queue<string> delete_queue = new Queue<string> ();

    public async List<Log> get_notes () {
        try {
            var contents = yield FileUtils.read_text_file (FILENAME);

            if (contents == null)
                return new List<Log> ();

            var json = Json.from_string (contents);

            if (json.get_node_type () != ARRAY)
                return new List<Log> ();

            return Log.list_from_json (json);
        } catch (Error err) {
            critical ("Error: %s", err.message);
            return new List<Log> ();
        }
    }

    public void insert_note (Log note) {
        insert_queue.push_tail (note);
    }

    public void update_note (Log note) {
        update_queue.push_tail (note);
    }

    public async void update_note_color (Log note, string color) {
        if (note != null) {
            var css_provider = new Gtk.CssProvider();
            string style = """
                .notejot-badge-%s {
                    background: mix(@view_bg_color, %s, 0.55);
                    border-radius: 999px;
                }
                .notejot-header-%s {
                    background: mix(@view_bg_color, %s, 0.1);
                }
                .notejot-footer-%s {
                    background: mix(@view_bg_color, %s, 0.1);
                }
                .notejot-view-%s text {
                    background: mix(@popover_bg_color, %s, 0.02);
                }
            """.printf( note.id,
                        color,
                        note.id,
                        color,
                        note.id,
                        color,
                        note.id,
                        color);
            css_provider.load_from_data(style.data);
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            note.color = color;

            update_queue.push_tail (note);
            save.begin ();
        }
    }

    public async void update_notebook (Log? note, string nb) {
        note.notebook = nb;
        update_queue.push_tail (note);
        save.begin ();
    }

    public void delete_note (string id) {
        delete_queue.push_tail (id);
    }

    public async bool save () {
        var notes = yield get_notes ();

        Log? note = null;
        while ((note = update_queue.pop_head ()) != null) {
            var current_note = search_note_by_id (notes, note.id);

            if (current_note == null) {
                insert_queue.push_tail (note);
                continue;
            }
            current_note.title = note.title;
            current_note.subtitle = note.subtitle;
            current_note.text = note.text;
            current_note.notebook = note.notebook;
            current_note.color = note.color;
            current_note.pinned = note.pinned;
        }

        string? note_id = null;
        while ((note_id = delete_queue.pop_head ()) != null) {
            note = search_note_by_id (notes, note_id);

            if (note == null)
                continue;

            notes.remove (note);
        }

        note = null;
        while ((note = insert_queue.pop_head ()) != null)
            notes.append (note);

        var json_array = new Json.Array ();
        foreach (var item in notes)
            json_array.add_element (item.to_json ());

        var node = new Json.Node (ARRAY);
        node.set_array (json_array);

        var str = Json.to_string (node, false);

        try {
            return yield FileUtils.create_text_file (FILENAME, str);
        } catch (Error err) {
              critical ("Error: %s", err.message);
              return false;
        }
    }

    public inline Log? search_note_by_id (List<Log> notes, string id) {
        unowned var link = notes.search<string> (id, (note, id) => strcmp (note.id, id));
        return link?.data;
    }
}
