namespace Notejot {
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/formatbar.ui")]
    public class Widgets.FormatBar : Gtk.ActionBar {
        public Widgets.TextField controller;
        public signal void clicked ();

        [GtkChild]
        Gtk.Button normal_button;

        [GtkChild]
        Gtk.Button bold_button;
        [GtkChild]
        Gtk.Button italic_button;
        [GtkChild]
        Gtk.Button ul_button;
        [GtkChild]
        Gtk.Button s_button;

        [GtkChild]
        Gtk.Button u_button;
        [GtkChild]
        Gtk.Button o_button;

        public FormatBar () {
            this.show_all ();

            normal_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            bold_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('bold');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            italic_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('italic');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            ul_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('underline');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            s_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('strikethrough');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            u_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('insertUnorderedList');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            o_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('insertOrderedList');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });
        }
    }
}
