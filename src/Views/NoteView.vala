/*
* Copyright (c) 2017-2020 Lains
*
* This program is free software; you can redistribute it and/or
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
namespace Notejot {
    public class Views.NoteView : Gtk.Grid {
        public MainWindow win;
        private static NoteView? instance = null;
        public Widgets.EditableLabel editablelabel;
        public Widgets.TextField textfield;

        public Gdk.RGBA color;

        public static NoteView get_instance () {
            if (instance == null) {
                instance = new Views.NoteView (Application.win);
            }

            return instance;
        }

        public NoteView (MainWindow win) {
            this.win = win;
            instance = this;

            textfield = new Widgets.TextField (win, "");            
            editablelabel = new Widgets.EditableLabel (win, "");

            editablelabel.changed.connect (() => {
                win.main_view.grid_view.flowgrid.selected_foreach ((item, child) => {
                    ((Widgets.TaskBox)child.get_child ()).task_label.set_label(editablelabel.title.get_label ());
                    ((Widgets.TaskBox)child.get_child ()).sidebaritem.title = editablelabel.title.get_label ();
                });
                win.tm.save_notes ();
            });

            var toolbar_revealer = new Gtk.Revealer ();
            var toolbar = new Gtk.ActionBar ();
            toolbar.get_style_context ().add_class ("notejot-abar");

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.get_style_context ().add_class ("vsep");

            var format_reset_button = new Gtk.Button ();
            format_reset_button.has_tooltip = true;
            format_reset_button.tooltip_text = (_("Remove Formatting"));
            format_reset_button.image = new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.BUTTON);
            format_reset_button.get_style_context ().add_class ("destructive-button");

            format_reset_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, str);""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_bold_button = new Gtk.Button ();
            format_bold_button.has_tooltip = true;
            format_bold_button.tooltip_text = (_("Bold Selected Text"));
            format_bold_button.image = new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.BUTTON);

            format_bold_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<b>"+str+"</b>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_italic_button = new Gtk.Button ();
            format_italic_button.has_tooltip = true;
            format_italic_button.tooltip_text = (_("Italic Selected Text"));
            format_italic_button.image = new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.BUTTON);

            format_italic_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<i>"+str+"</i>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_ul_button = new Gtk.Button ();
            format_ul_button.has_tooltip = true;
            format_ul_button.tooltip_text = (_("Underline Selected Text"));
            format_ul_button.image = new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.BUTTON);

            format_ul_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<u>"+str+"</u>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            color.red = 0.0;
            color.blue = 0.0;
            color.green = 0.0;
            color.alpha = 255.0;

            var format_color_button = new Gtk.ColorButton.with_rgba (color);
            format_color_button.has_tooltip = true;
            format_color_button.tooltip_text = (_("Color Selected Text"));
            format_color_button.title = (_("Color for Selected Text"));
            format_color_button.use_alpha = false;

            format_color_button.color_set.connect (() => {
                color = format_color_button.get_rgba();
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<span style='color: %s'>"+str+"</span>");""".printf(color.to_string()));
                textfield.send_text ();
                win.tm.save_notes ();
            });

            toolbar.pack_start (format_reset_button);
            toolbar.pack_start (sep);
            toolbar.pack_start (format_bold_button);
            toolbar.pack_start (format_italic_button);
            toolbar.pack_start (format_ul_button);
            toolbar.pack_start (format_color_button);

            toolbar_revealer.add (toolbar);
            toolbar_revealer.show_all ();
            toolbar_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                textfield.get_style_context ().add_class ("notejot-tview-dark");
                toolbar.get_style_context ().add_class ("notejot-abar-dark");
                textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                textfield.get_style_context ().remove_class ("notejot-tview-dark");
                textfield.update_html_view ();
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                    textfield.get_style_context ().add_class ("notejot-tview-dark");
                    toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                    toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    textfield.get_style_context ().remove_class ("notejot-tview-dark");
                    textfield.update_html_view ();
                }

                toolbar_revealer.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");
            });

            win.sidebar.sidebar_button.clicked.connect (() => {
                if (win.main_view.stack.get_visible_child () == this) {
                    win.main_view.stack.set_visible_child (win.main_view.grid_view);

                    win.main_view.grid_view.flowgrid.selected_foreach ((item, child) => {
                        win.main_view.stack.remove (this);
                    });
                }
            });

            this.orientation = Gtk.Orientation.VERTICAL;
            this.add (toolbar_revealer);
            this.add (editablelabel);
            this.add (textfield);
            this.show_all ();
        }
    }
}