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
                controller.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.body.innerHTML = document.body.innerHTML.replace(str, str);""");
                controller.send_text.begin ();
                win.tm.save_notes.begin ();
            });

            var bold_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Bold selected text"))
            };

            bold_button.clicked.connect (() => {
                controller.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.body.innerHTML = document.body.innerHTML.replace(str, "<b>"+str+"</b>");""");
                controller.send_text.begin ();
                win.tm.save_notes.begin ();
            });

            var italic_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Italicise selected text"))
            };

            italic_button.clicked.connect (() => {
                controller.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.body.innerHTML = document.body.innerHTML.replace(str, "<i>"+str+"</i>");""");
                controller.send_text.begin ();
                win.tm.save_notes.begin ();
            });

            var ul_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Underline selected text"))
            };

            ul_button.clicked.connect (() => {
                controller.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.body.innerHTML = document.body.innerHTML.replace(str, "<u>"+str+"</u>");""");
                controller.send_text.begin ();
                win.tm.save_notes.begin ();
            });

            var s_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("format-text-strikethrough-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Draw a line through selected text"))
            };

            s_button.clicked.connect (() => {
                controller.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.body.innerHTML = document.body.innerHTML.replace(str, "<s>"+str+"</s>");""");
                controller.send_text.begin ();
                win.tm.save_notes.begin ();
            });

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.row_spacing = 6;
            grid.add (normal_button);
            grid.add (bold_button);
            grid.add (italic_button);
            grid.add (ul_button);
            grid.add (s_button);
            grid.show_all ();

            this.add(grid);
            this.show_all ();
        }
    }
}
