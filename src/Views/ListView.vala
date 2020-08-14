namespace Notejot {
    public class Views.ListView : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public ListView (MainWindow win) {
            var no_files = new Gtk.Label (_("No notes…"));
            no_files.halign = Gtk.Align.CENTER;
            var no_files_style_context = no_files.get_style_context ();
            no_files_style_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            no_files_style_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            no_files.show_all ();

            this.win = win;
            this.expand = true;
            is_modified = false;
            set_sort_func (list_sort);
            set_placeholder (no_files);

            this.get_style_context ().add_class ("notejot-lview");
            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                this.get_style_context ().add_class ("notejot-lview-bg-dark");
                this.get_style_context ().remove_class ("notejot-lview-bg");
            } else {
                this.get_style_context ().remove_class ("notejot-lview-bg-dark");
                this.get_style_context ().add_class ("notejot-lview-bg");
            }

            Notejot.Application.gsettings.changed["dark-mode"].connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    this.get_style_context ().add_class ("notejot-lview-bg-dark");
                    this.get_style_context ().remove_class ("notejot-lview-bg");
                } else {
                    this.get_style_context ().remove_class ("notejot-lview-bg-dark");
                    this.get_style_context ().add_class ("notejot-lview-bg");
                }
            });

            var provider2 = new Gtk.CssProvider ();
            string res1 = "\"resource:///com/github/lainsce/notejot/image/bg1.png\"";
            string res2 = "\"resource:///com/github/lainsce/notejot/image/bg2.png\"";
            string css = """
                .notejot-lview-bg {
                    background-image: url(%s);
                    background-repeat: repeat;
                }
                .notejot-lview-bg-dark {
                    background-image: url(%s);
                    background-repeat: repeat;
                }
             """.printf(res1, res2);
             try {
                provider2.load_from_data(css, -1);
             } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
             }
             Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider2, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            this.show_all ();
        }

        public GLib.List<unowned Widgets.TaskBox> get_rows () {
            return (GLib.List<unowned Widgets.TaskBox>) this.get_children ();
        }

        public void clear_column () {
            foreach (Gtk.Widget item in this.get_children ()) {
                item.destroy ();
            }
            win.tm.save_notes ();
        }

        public Gee.ArrayList<Gtk.ListBoxRow> get_tasks () {
            var tasks = new Gee.ArrayList<Gtk.ListBoxRow> ();
            foreach (Gtk.Widget item in this.get_children ()) {
	            tasks.add ((Gtk.ListBoxRow)item);
            }
            return tasks;
        }

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }
    }
}