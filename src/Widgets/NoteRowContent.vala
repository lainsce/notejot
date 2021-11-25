[GtkTemplate (ui = "/io/github/lainsce/Notejot/noterowcontent.ui")]
public class Notejot.NoteRowContent : Adw.Bin {
    public Note? cnote { get; set;}

    public NoteRowContent (Note note) {
        Object(
            cnote: note
        );
    }

    [GtkCallback]
    string get_subtitle_line () {
        return cnote.notebook + " – " + cnote.text;
    }
}
