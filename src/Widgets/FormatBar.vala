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
        public unowned Gtk.Label notebooklabel;
        [GtkChild]
        public unowned Gtk.Box nb_box;

        public FormatBar () {
            this.show_all ();

            normal_button.clicked.connect (() => {
                var sel_text = controller.get_selected_text ();
                Gtk.TextIter A;
                Gtk.TextIter B;
                controller.get_buffer ().get_selection_bounds (out A, out B);

                controller.get_buffer ().insert_markup(ref A, @"$sel_text", -1);
                controller.get_buffer ().delete_selection (true, true);
                controller.grab_focus ();
            });

            bold_button.clicked.connect (() => {
                var sel_text = controller.get_selected_text ();
                Gtk.TextIter A;
                Gtk.TextIter B;
                controller.get_buffer ().get_selection_bounds (out A, out B);

                controller.get_buffer ().insert_markup(ref A, @"<b>$sel_text</b>", -1);
                controller.get_buffer ().delete_selection (true, true);
                controller.grab_focus ();
            });

            italic_button.clicked.connect (() => {
                var sel_text = controller.get_selected_text ();
                Gtk.TextIter A;
                Gtk.TextIter B;
                controller.get_buffer ().get_selection_bounds (out A, out B);

                controller.get_buffer ().insert_markup(ref A, @"<i>$sel_text</i>", -1);
                controller.get_buffer ().delete_selection (true, true);
                controller.grab_focus ();
            });

            ul_button.clicked.connect (() => {
                var sel_text = controller.get_selected_text ();
                Gtk.TextIter A;
                Gtk.TextIter B;
                controller.get_buffer ().get_selection_bounds (out A, out B);

                controller.get_buffer ().insert_markup(ref A, @"<u>$sel_text</u>", -1);
                controller.get_buffer ().delete_selection (true, true);
                controller.grab_focus ();
            });

            s_button.clicked.connect (() => {
                var sel_text = controller.get_selected_text ();
                Gtk.TextIter A;
                Gtk.TextIter B;
                controller.get_buffer ().get_selection_bounds (out A, out B);

                controller.get_buffer ().insert_markup(ref A, @"<s>$sel_text</s>", -1);
                controller.get_buffer ().delete_selection (true, true);
                controller.grab_focus ();
            });
        }
    }
}
