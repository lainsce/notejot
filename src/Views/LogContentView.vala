[GtkTemplate (ui = "/io/github/lainsce/Notejot/logcontentview.ui")]
public class Notejot.LogContentView : View {
    Log? _note;
    public LogViewModel? vm {get; set;}

    public LogContent? lc;

    [GtkChild]
    public unowned Gtk.Stack stack;
    [GtkChild]
    public unowned Gtk.Stack note_stack;

    [GtkChild]
    public unowned Adw.StatusPage empty_view;

    public Log? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            _note = value;

            lc = new LogContent (vm);
            lc.note = _note;
            note_stack.add_named (lc, "content-%s".printf(_note.id));

            stack.visible_child = _note != null ? (Gtk.Widget) note_stack : empty_view;
        }
    }

    public LogContentView (LogViewModel? vm) {
        Object (vm: vm);
    }

    public signal void note_update_requested (Log note);

    void on_text_updated () {
        note_update_requested (note);
    }
}
