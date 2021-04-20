namespace Notejot {
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/formatbar.ui")]
    public class Widgets.FormatBar : Gtk.ActionBar {
        public Widgets.TextField controller;
        public signal void clicked ();

        [GtkChild]
        unowned Gtk.Button normal_button;

        [GtkChild]
        unowned Gtk.Button bold_button;
        [GtkChild]
        unowned Gtk.Button italic_button;
        [GtkChild]
        unowned Gtk.Button ul_button;
        [GtkChild]
        unowned Gtk.Button s_button;

        [GtkChild]
        unowned Gtk.Button u_button;
        [GtkChild]
        unowned Gtk.Button o_button;

        [GtkChild]
        public unowned Gtk.Label notebooklabel;
        [GtkChild]
        public unowned Gtk.Box nb_box;

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
