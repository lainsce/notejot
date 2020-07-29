/*
* Copyright (c) 2017-2020 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
        private MainWindow win;
        public Gtk.ActionBar toolbar;
        public Gtk.Revealer toolbar_revealer;
        public Widgets.TextField textfield;
        public Widgets.EditableLabel editablelabel;
        public Gdk.RGBA color;

        public NoteView (MainWindow win) {
            this.win = win;
            
            textfield = new Widgets.TextField (win);
            editablelabel = new Widgets.EditableLabel (win, "");

            // Toolbar with Note formatting options
            toolbar = new Gtk.ActionBar ();
            toolbar.get_style_context ().add_class ("notejot-abar");

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.get_style_context ().add_class ("vsep");

            var format_reset_button = new Gtk.Button () {
                tooltip_text = (_("Remove Formatting")),
                image = new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.BUTTON)
            };
            format_reset_button.get_style_context ().add_class ("destructive-button");

            format_reset_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHwin.TML = document.getElementById("textarea").innerHwin.TML.replace(str, str);""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_bold_button = new Gtk.Button () {
                tooltip_text = (_("Bold Selected Text")),
                image = new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.BUTTON)
            };

            format_bold_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHwin.TML = document.getElementById("textarea").innerHwin.TML.replace(str, "<b>"+str+"</b>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_italic_button = new Gtk.Button () {
                tooltip_text = (_("Italic Selected Text")),
                image = new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.BUTTON)
            };

            format_italic_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHwin.TML = document.getElementById("textarea").innerHwin.TML.replace(str, "<i>"+str+"</i>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_ul_button = new Gtk.Button () {
                tooltip_text = (_("Underline Selected Text")),
                image = new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.BUTTON)
            };

            format_ul_button.clicked.connect (() => {
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHwin.TML = document.getElementById("textarea").innerHwin.TML.replace(str, "<u>"+str+"</u>");""");
                textfield.send_text ();
                win.tm.save_notes ();
            });

            color.red = 0.0;
            color.blue = 0.0;
            color.green = 0.0;
            color.alpha = 255.0;

            var format_color_button = new Gtk.ColorButton.with_rgba (color) {
                tooltip_text = (_("Color Selected Text")),
                use_alpha = false
            };

            format_color_button.color_set.connect (() => {
                color = format_color_button.get_rgba();
                textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHwin.TML = document.getElementById("textarea").innerHwin.TML.replace(str, "<span style='color: %s'>"+str+"</span>");""".printf(color.to_string()));
                textfield.send_text ();
                win.tm.save_notes ();
            });

            toolbar.pack_start (format_reset_button);
            toolbar.pack_start (sep);
            toolbar.pack_start (format_bold_button);
            toolbar.pack_start (format_italic_button);
            toolbar.pack_start (format_ul_button);
            toolbar.pack_start (format_color_button);

            toolbar_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
                reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar")
            };
            toolbar_revealer.add (toolbar);

            win.format_button.toggled.connect (() => {
                if (Notejot.Application.gsettings.get_boolean ("show-formattingbar")) {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", false);
                    toolbar_revealer.reveal_child = false;
                } else {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", true);
                    toolbar_revealer.reveal_child = true;
                }
                win.tm.save_notes ();
            });

            this.attach (toolbar_revealer, 0, 0);
            this.attach (editablelabel, 0, 1);
            this.attach (textfield, 0, 2);

            this.orientation = Gtk.Orientation.VERTICAL;
            this.show_all ();
        }
    }
}