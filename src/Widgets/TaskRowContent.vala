/*
* Copyright (C) 2017-2021 Lains
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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/taskrowcontent.ui")]
public class Notejot.TaskRowContent : He.Bin {
    [GtkChild]
    private unowned Gtk.Box row_box;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_red;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_orange;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_yellow;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_green;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_blue;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_brown;
    [GtkChild]
    private unowned Gtk.CheckButton color_button_purple;
    [GtkChild]
    private unowned Gtk.Button delete_button;

    private Binding? color_binding;
    private Gtk.CssProvider provider = new Gtk.CssProvider();

    private string? _color;
    public string? color {
        get { return _color; }
        set {
            if (value == _color)
                return;

            _color = value;

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_task.color));
            ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, _color);
            row_box.get_style_context().add_provider(provider, 1);
        }
    }

    private Task? _task;
    public Task? task {
        get { return _task; }
        set {
            if (value == _task)
                return;

            color_binding?.unbind ();

            _task = value;

            color_button_red.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #a51d2d;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#a51d2d");
                }
            });

            color_button_orange.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #c64600;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#c64600");
                }
            });

            color_button_yellow.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #e5a50a;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#e5a50a");
                }
            });

            color_button_green.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #26a269;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#26a269");
                }
            });

            color_button_blue.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #1a5fb4;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#1a5fb4");
                }
            });

            color_button_purple.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #613583;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#613583");
                }
            });

            color_button_brown.toggled.connect (() => {
                if (_task != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #63452c;");
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).tsview_model.update_task_color (_task, "#63452c");
                }
            });

            delete_button.clicked.connect (() => {
                if (_task != null) {
                    ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).task_removal_requested (_task);
                }
            });

            color_binding = _task?.bind_property (
                "color", this, "color", SYNC_CREATE|BIDIRECTIONAL);
        }
    }

    public TaskRowContent (Task task) {
        Object(
            task: task
        );
    }

    construct {
        row_box.get_style_context().add_provider(provider, 1);
    }

    ~TaskRowContent () {
        while (this.get_first_child () != null) {
            var c = this.get_first_child ();
            c.unparent ();
        }
        this.unparent ();
    }

    [GtkCallback]
    string get_subtitle_line () {
        return task.text;
    }
}
