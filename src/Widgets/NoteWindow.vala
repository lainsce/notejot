namespace Notejot {
    public class Widgets.NoteWindow : Gtk.Application {
        private Hdy.Window window;
        private int uid;
        private static NoteWindow? instance = null;

        public Gdk.RGBA colors;
        public Gtk.ActionBar toolbar;
        public Gtk.Revealer toolbar_revealer;
        public Gtk.ToggleButton format_button;
        public MainWindow? win;

        public string contents;
        public string title;

        public Widgets.EditableLabel? editablelabel;
        public Widgets.TextField? textfield;

        public static NoteWindow get_instance () {
            return instance;
        }

        public NoteWindow (MainWindow win, Widgets.TaskContentView tcv, string title, string contents, int uid) {
            this.win = win;
            this.title = title;
            this.contents = contents;
            this.uid = uid;

            window = new Hdy.Window ();

            var notebar = new Hdy.HeaderBar ();
            notebar.show_close_button = true;
            notebar.has_subtitle = false;
            notebar.set_size_request (-1, 30);
            notebar.set_decoration_layout ("close:");
            notebar.get_style_context ().add_class ("notejot-nbar-%d".printf(this.uid));
            notebar.set_title (this.title);
            
            window.title = this.title;
            window.set_size_request (375, 375);
            window.show_all ();
            instance = this;

            format_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options"))
            };
            format_button.get_style_context ().add_class ("notejot-button");

            var sync_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Sync Note")),
                visible = true
            };
            sync_button.get_style_context ().add_class ("notejot-button");
            notebar.pack_end (sync_button);
            notebar.pack_end (format_button);

            // Note View
            var textfield = new Widgets.TextField (win);            
            editablelabel = new Widgets.EditableLabel (win, this.title);
            toolbar = new Gtk.ActionBar ();
            toolbar.get_style_context ().add_class ("notejot-abar");

            textfield.text = this.contents;
            // Hella hackish JavaScript but to make it work it's needed.
            textfield.run_javascript.begin("""var str = document.getElementById("textarea").outerHTML;document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, str);""");
            textfield.update_html_view ();

            sync_button.clicked.connect (() => {
                // Hella hackish JavaScript but to make it work it's needed.
                textfield.run_javascript.begin("""var str = document.getElementById("textarea").outerHTML;document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, str);""");
                textfield.send_text ();
                tcv.text = textfield.text;
                tcv.send_text ();
                tcv.reload_bypass_cache ();
                tcv.update_html_view ();
                win.tm.save_notes ();
            });

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.get_style_context ().add_class ("vsep");

            var format_reset_button = new Gtk.Button ();
            format_reset_button.has_tooltip = true;
            format_reset_button.tooltip_text = (_("Remove Formatting"));
            format_reset_button.image = new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.BUTTON);
            format_reset_button.get_style_context ().add_class ("destructive-button");

            format_reset_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, str);""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_bold_button = new Gtk.Button ();
            format_bold_button.has_tooltip = true;
            format_bold_button.tooltip_text = (_("Bold Selected Text"));
            format_bold_button.image = new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.BUTTON);

            format_bold_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<b>"+str+"</b>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_italic_button = new Gtk.Button ();
            format_italic_button.has_tooltip = true;
            format_italic_button.tooltip_text = (_("Italic Selected Text"));
            format_italic_button.image = new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.BUTTON);

            format_italic_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<i>"+str+"</i>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_ul_button = new Gtk.Button ();
            format_ul_button.has_tooltip = true;
            format_ul_button.tooltip_text = (_("Underline Selected Text"));
            format_ul_button.image = new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.BUTTON);

            format_ul_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<u>"+str+"</u>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            colors.red = 0.0;
            colors.blue = 0.0;
            colors.green = 0.0;
            colors.alpha = 255.0;

            var format_color_button = new Gtk.ColorButton.with_rgba (colors);
            format_color_button.has_tooltip = true;
            format_color_button.tooltip_text = (_("Color Selected Text"));
            format_color_button.title = (_("Color for Selected Text"));
            format_color_button.use_alpha = false;

            format_color_button.color_set.connect (() => {
                colors = format_color_button.get_rgba();
                textfield.run_javascript.begin("""var str = window.getSelection().toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<span style='color: %s'>"+str+"</span>");""".printf(colors.to_string()));
                textfield.send_text ();
                win.tm.save_notes ();
            });

            toolbar.pack_start (format_reset_button);
            toolbar.pack_start (sep);
            toolbar.pack_start (format_bold_button);
            toolbar.pack_start (format_italic_button);
            toolbar.pack_start (format_ul_button);
            toolbar.pack_start (format_color_button);

            toolbar_revealer = new Gtk.Revealer ();
            toolbar_revealer.add (toolbar);
            toolbar_revealer.show_all ();
            toolbar_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");

            editablelabel.changed.connect (() => {
                win.flowgrid.selected_foreach ((item, child) => {
                    ((Widgets.TaskBox)child.get_child ()).task_label.set_label(editablelabel.title.get_label ());
                    ((Widgets.TaskBox)child.get_child ()).sidebaritem.title = editablelabel.title.get_label ();
                    ((Widgets.TaskBox)child.get_child ()).title = editablelabel.title.get_label ();
                    ((Widgets.TaskBox)child.get_child ()).taskline.task_label.label = editablelabel.title.get_label ();
                    notebar.set_title (editablelabel.title.get_label ());
                });
                win.tm.save_notes ();
            });

            var notegrid = new Gtk.Grid ();
            notegrid.orientation = Gtk.Orientation.VERTICAL;
            notegrid.add (notebar);
            notegrid.add (toolbar_revealer);
            notegrid.add (textfield);
            notegrid.show_all ();

            notebar.set_custom_title (editablelabel);
            window.add (notegrid);
            window.show_all ();

            format_button.toggled.connect (() => {
                if (Notejot.Application.gsettings.get_boolean ("show-formattingbar")) {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", false);
                    toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");
                } else {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", true);
                    toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");
                }
            });

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                textfield.get_style_context ().add_class ("notejot-tview-dark");
                toolbar.get_style_context ().add_class ("notejot-abar-dark");
                notebar.get_style_context ().add_class ("notejot-nbar-dark-%d".printf(uid));
                textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                textfield.get_style_context ().remove_class ("notejot-tview-dark");
                notebar.get_style_context ().remove_class ("notejot-nbar-dark-%d".printf(uid));
                textfield.update_html_view ();
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.get_style_context ().add_class ("notejot-tview-dark");
                    toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    notebar.get_style_context ().add_class ("notejot-nbar-dark-%d".printf(uid));
                    textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    textfield.get_style_context ().remove_class ("notejot-tview-dark");
                    notebar.get_style_context ().remove_class ("notejot-nbar-dark-%d".printf(uid));
                    textfield.update_html_view ();
                }
                toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");
            });

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.get_style_context ().add_class ("notejot-tview-dark");
                    toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    notebar.get_style_context ().add_class ("notejot-nbar-dark-%d".printf(uid));
                    textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    textfield.get_style_context ().remove_class ("notejot-tview-dark");
                    notebar.get_style_context ().remove_class ("notejot-nbar-dark-%d".printf(uid));
                    textfield.update_html_view ();
                }
                toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");
            });

            window.delete_event.connect (() => {
                win.tm.save_notes ();
                instance = null;
                return false;
            });
        }
    }
}