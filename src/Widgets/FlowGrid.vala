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
    public class Widgets.FlowGrid : Gtk.FlowBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public FlowGrid (MainWindow win) {
            this.win = win;
            this.valign = Gtk.Align.START;
            this.expand = true;
            this.column_spacing = this.row_spacing = 12;
            this.max_children_per_line = 3;
            this.activate_on_single_click = true;
            this.selection_mode = Gtk.SelectionMode.SINGLE;
            
            is_modified = false;

            this.child_activated.connect ((item) => {
                if (item != null && ((Widgets.TaskBox)item.get_child ()).note_view.editablelabel != null && win.stack != null) {
                    ((Widgets.TaskBox)item.get_child ()).note_view.editablelabel.text = ((Widgets.TaskBox)item.get_child ()).task_label.get_label();
                    ((Widgets.TaskBox)item.get_child ()).note_view.textfield.text = ((Widgets.TaskBox)item.get_child ()).task_contents.get_label();
                    ((Widgets.TaskBox)item.get_child ()).note_view.textfield.update_html_view ();
                    win.stack.set_visible_child (((Widgets.TaskBox)item.get_child ()).note_view);
                    win.titlebar.format_button.sensitive = true;
                }
            });

            this.get_style_context ().add_class ("notejot-fgview");
            this.show_all ();
        }

        public Gee.ArrayList<Gtk.FlowBoxChild> get_tasks () {
            var tasks = new Gee.ArrayList<Gtk.FlowBoxChild> ();
            foreach (Gtk.Widget item in this.get_children ()) {
	            tasks.add ((Gtk.FlowBoxChild)item);
            }
            return tasks;
        }
    }
}