/*
* Copyright (C) 2017-2020 Lains
*
* This program is free software; you can redistribute it &&/or
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
    public class Widgets.Toolbar : Gtk.Revealer {
        public MainWindow win;
        public Views.NoteView view;
        public Gdk.RGBA color;
        public Gtk.ActionBar toolbar;

        public Toolbar (MainWindow win, Views.NoteView view) {
            this.win = win;
            this.view = view;

            toolbar = new Gtk.ActionBar ();
            toolbar.get_style_context ().add_class ("notejot-abar");

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.get_style_context ().add_class ("vsep");

            var format_reset_button = new Gtk.Button ();
            format_reset_button.has_tooltip = true;
            format_reset_button.tooltip_text = (_("Remove Formatting"));
            format_reset_button.image = new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.BUTTON);
            format_reset_button.get_style_context ().add_class ("destructive-button");

            format_reset_button.clicked.connect (() => {
                view.textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, str);""");
                view.textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_bold_button = new Gtk.Button ();
            format_bold_button.has_tooltip = true;
            format_bold_button.tooltip_text = (_("Bold Selected Text"));
            format_bold_button.image = new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.BUTTON);

            format_bold_button.clicked.connect (() => {
                view.textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<b>"+str+"</b>");""");
                view.textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_italic_button = new Gtk.Button ();
            format_italic_button.has_tooltip = true;
            format_italic_button.tooltip_text = (_("Italic Selected Text"));
            format_italic_button.image = new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.BUTTON);

            format_italic_button.clicked.connect (() => {
                view.textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<i>"+str+"</i>");""");
                view.textfield.send_text ();
                win.tm.save_notes ();
            });

            var format_ul_button = new Gtk.Button ();
            format_ul_button.has_tooltip = true;
            format_ul_button.tooltip_text = (_("Underline Selected Text"));
            format_ul_button.image = new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.BUTTON);

            format_ul_button.clicked.connect (() => {
                view.textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<u>"+str+"</u>");""");
                view.textfield.send_text ();
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
                view.textfield.run_javascript.begin("""var str = window.getSelection().getRangeAt(0).toString();document.execCommand('removeFormat');document.getElementById("textarea").innerHTML = document.getElementById("textarea").innerHTML.replace(str, "<span style='color: %s'>"+str+"</span>");""".printf(color.to_string()));
                view.textfield.send_text ();
                win.tm.save_notes ();
            });

            toolbar.pack_start (format_reset_button);
            toolbar.pack_start (sep);
            toolbar.pack_start (format_bold_button);
            toolbar.pack_start (format_italic_button);
            toolbar.pack_start (format_ul_button);
            toolbar.pack_start (format_color_button);

            view.win.format_button.toggled.connect (() => {
                if (Notejot.Application.gsettings.get_boolean ("show-formattingbar")) {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", false);
                    this.reveal_child = false;
                } else {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", true);
                    this.reveal_child = true;
                }
                win.tm.save_notes ();
            });

            this.add (toolbar);
            this.show_all ();
            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.reveal_child = Notejot.Application.gsettings.get_boolean ("show-formattingbar");
        }
    }
}