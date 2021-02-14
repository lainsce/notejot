namespace Notejot {
    public class Widgets.FormatBar : Gtk.ActionBar {
        private MainWindow win;
        public Widgets.TextField controller;

        public FormatBar (MainWindow win) {
            this.win = win;
            this.get_style_context ().add_class ("notejot-bar");

            var normal_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Remove formatting"))
            };

            normal_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var bold_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Bold selected text"))
            };

            bold_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('bold');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var italic_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Italicise selected text"))
            };

            italic_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('italic');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var ul_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Underline selected text"))
            };

            ul_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('underline');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var s_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-strikethrough-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Draw a line through selected text"))
            };

            s_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('strikethrough');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var u_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("view-list-bullet-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Selected text becomes an unordered list"))
            };

            u_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('insertUnorderedList');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var o_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("view-list-ordered-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Selected text becomes an ordered list"))
            };

            o_button.clicked.connect (() => {
                controller.run_javascript.begin("""document.execCommand('removeFormat');document.execCommand('insertOrderedList');""");
                controller.send_text.begin ();
                controller.grab_focus ();
            });

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            var sep2 = new Gtk.Separator (Gtk.Orientation.VERTICAL);

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.row_spacing = 6;
            grid.add (normal_button);
            grid.add (sep);
            grid.add (bold_button);
            grid.add (italic_button);
            grid.add (ul_button);
            grid.add (s_button);
            grid.add (sep2);
            grid.add (u_button);
            grid.add (o_button);
            grid.show_all ();

            this.add(grid);
            this.show_all ();
        }
    }
}
