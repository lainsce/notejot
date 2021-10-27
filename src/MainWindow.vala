/*
* Copyright (c) 2017-2021 Lains
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
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/main_window.ui")]
    public class MainWindow : Adw.ApplicationWindow {
        delegate void HookFunc ();

        [GtkChild]
        public unowned Gtk.Button new_button;
        [GtkChild]
        public unowned Gtk.Button back_button;
        [GtkChild]
        public unowned Gtk.MenuButton menu_button;
        [GtkChild]
        public unowned Gtk.MenuButton settingmenu;
        [GtkChild]
        public unowned Gtk.SearchEntry note_search;

        [GtkChild]
        public unowned Gtk.Box grid;
        [GtkChild]
        public unowned Gtk.Box sgrid;
        [GtkChild]
        public unowned Gtk.Box empty_state;
        [GtkChild]
        public unowned Adw.Leaflet leaflet;
        [GtkChild]
        public unowned Gtk.Box list_scroller;
        [GtkChild]
        public unowned Gtk.Box trash_scroller;
        [GtkChild]
        public unowned Gtk.ListBox listview;
        [GtkChild]
        public unowned Gtk.ListBox trashview;

        [GtkChild]
        public unowned Gtk.Stack main_stack;
        [GtkChild]
        public unowned Gtk.Stack sidebar_stack;
        [GtkChild]
        public new unowned Adw.HeaderBar titlebar;
        [GtkChild]
        public unowned Adw.HeaderBar stitlebar;

        // Custom
        public Widgets.SettingMenu sm;
        public Widgets.HeaderBarButton hbb;
        public Views.ListView lv;
        public Views.TrashView tv;
        public TaskManager tm;

        // Etc
        int uid = 0;
        public Gtk.Settings gtk_settings;

        public GLib.ListStore notestore;
        public GLib.ListStore trashstore;
        public GLib.ListStore notebookstore;

        public Gtk.Builder tbuilder;

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ABOUT = "action_about";
        public const string ACTION_NEW_NOTE = "action_new_note";
        public const string ACTION_ALL_NOTES = "action_all_notes";
        public const string ACTION_TRASH = "action_trash";
        public const string ACTION_KEYS = "action_keys";
        public const string ACTION_TRASH_NOTES = "action_trash_notes";
        public const string ACTION_MOVE_TO = "action_move_to";
        public const string ACTION_DELETE_NOTE = "action_delete_note";
        public const string ACTION_RESTORE_NOTE = "action_restore_note";
        public const string ACTION_EDIT_NOTEBOOKS = "action_edit_notebooks";
        public const string ACTION_NOTEBOOK = "select_notebook";
        public const string ACTION_PIN_NOTE = "action_pin_note";

        public const string ACTION_NORMAL = "action_normal";
        public const string ACTION_BOLD = "action_bold";
        public const string ACTION_ITALIC = "action_italic";
        public const string ACTION_UL = "action_ul";
        public const string ACTION_S = "action_s";
        public const string ACTION_ITEM = "action_item";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
              {ACTION_ABOUT, action_about },
              {ACTION_NEW_NOTE, action_new_note },
              {ACTION_ALL_NOTES, action_all_notes},
              {ACTION_TRASH, action_trash},
              {ACTION_KEYS, action_keys},
              {ACTION_TRASH_NOTES, action_trash_notes},
              {ACTION_MOVE_TO, action_move_to},
              {ACTION_DELETE_NOTE, action_delete_note},
              {ACTION_RESTORE_NOTE, action_restore_note},
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},
              {ACTION_NOTEBOOK, select_notebook, "s"},
              {ACTION_PIN_NOTE, action_pin_note},

              {ACTION_NORMAL, action_normal },
              {ACTION_BOLD, action_bold},
              {ACTION_ITALIC, action_italic},
              {ACTION_UL, action_ul},
              {ACTION_S, action_s},
              {ACTION_ITEM, action_item},
        };

        public Adw.Application app { get; construct; }
        public MainWindow (Adw.Application application) {
            GLib.Object (
                application: application,
                app: application,
                icon_name: Config.APP_ID,
                title: (_("Notejot"))
            );
        }

        construct {
            // Initial settings

            // This css provider still needed due to custom css in-app
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/github/lainsce/Notejot/style.css");
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
            default_theme.add_resource_path ("/io/github/lainsce/Notejot");

            // Actions
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                var accels_array = action_accelerators[action].to_array ();
                accels_array += null;

                app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
            }
            app.set_accels_for_action("app.quit", {"<Ctrl>q"});
            app.set_accels_for_action ("win.action_new_note", {"<Ctrl>n"});

            app.set_accels_for_action ("win.action_normal", {"<Ctrl>t"});
            app.set_accels_for_action ("win.action_bold", {"<Ctrl>b"});
            app.set_accels_for_action ("win.action_italic", {"<Ctrl>i"});
            app.set_accels_for_action ("win.action_ul", {"<Ctrl>u"});
            app.set_accels_for_action ("win.action_s", {"<Ctrl><Shift>s"});

            var action_fontsize = Notejot.Application.gsettings.create_action ("font-size");
            app.add_action(action_fontsize);
            
            // Dark theme
            var adwsm = Adw.StyleManager.get_default ();
            adwsm.set_color_scheme (Adw.ColorScheme.PREFER_LIGHT);

            // Main View
            tm = new TaskManager (this);
            sm = new Widgets.SettingMenu(this);
            settingmenu.visible = false;

            titlebar.get_style_context ().add_class ("notejot-empty-title");

            back_button.clicked.connect (() => {
                main_stack.set_visible_child (empty_state);
                if (listview.get_selected_row () != null) {
                    listview.unselect_row(listview.get_selected_row ());
                }
                settingmenu.visible = false;
                lv.set_search_text ("");
                leaflet.set_visible_child (sgrid);
            });

            // Sidebar Titlebar
            var builder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/menu.ui");
            menu_button.menu_model = (MenuModel)builder.get_object ("menu");

            notestore = new GLib.ListStore (typeof (Log));
            trashstore = new GLib.ListStore (typeof (TrashLog));

            // List View
            lv = new Views.ListView (this);
            listview.bind_model (notestore, item => make_item (this, item));
            notestore.items_changed.connect (() => {
                tm.save_notes.begin (notestore);
            });
            notestore.sort ((a, b) => {
                if (((Log)a).pinned) {
                    return -1;
                }

                return 0;
            });

            // Trash View
            tv = new Views.TrashView (this);
            trashview.bind_model (trashstore, titem => make_trash_item (this, titem));

            trashstore.items_changed.connect (() => {
                tm.save_trash_notes.begin (trashstore);
            });

            tbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/title_menu.ui");
            var tmenu = (Menu)tbuilder.get_object ("tmenu");

            hbb = new Widgets.HeaderBarButton ();
            hbb.has_tooltip = true;
            hbb.title = (_("All Notes"));
            hbb.menu.menu_model = tmenu;
            hbb.get_style_context ().add_class ("rename-button");
            hbb.get_style_context ().add_class ("flat");

            stitlebar.set_title_widget (hbb);

            var sbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/note_menu.ui");
            var smenu = (Menu)sbuilder.get_object ("smenu");

            settingmenu.menu_model = smenu;

            var popover = settingmenu.get_popover ();
            popover.add_child (sbuilder, sm.nmp, "theme");

            note_search.notify["text"].connect (() => {
               lv.set_search_text (note_search.get_text ());
            });

            notebookstore = new GLib.ListStore (typeof (Notebook));
            notebookstore.items_changed.connect (() => {
                tm.save_notebooks.begin (notebookstore);
                ((Menu)tbuilder.get_object ("edit")).remove_all ();

                uint i, n = notebookstore.get_n_items ();
                for (i = 0; i < n; i++) {
                    var item = notebookstore.get_item (i);
                    string notebook_name = (((Notebook)item).title);

                    var menuitem = new GLib.MenuItem (notebook_name, null);
                    menuitem.set_action_and_target_value ("win.select_notebook", notebook_name);

                    ((Menu)tbuilder.get_object ("edit")).insert_item (-1, menuitem);
                }
            });

            // Preparing window to be shown
            set_default_size(
                Application.gsettings.get_int ("window-w"),
                Application.gsettings.get_int ("window-h")
            );

            if (Application.gsettings.get_boolean("is-maximized"))
                maximize ();

            this.show ();

            load_all_notes ();
        }

        protected override bool close_request () {
            debug ("Exiting window... Disposing of stuff...");

            Application.gsettings.set_boolean("is-maximized", is_maximized ());

            if (!is_maximized()) {
                Application.gsettings.set_int("window-w", get_width ());
                Application.gsettings.set_int("window-h", get_height ());
            }

            this.dispose ();
            return true;
        }

        // IO?
        public void load_all_notes () {
            tm.load_from_file_trash.begin ();
            tm.load_from_file_notes.begin ();
            tm.load_from_file_nb.begin ();
        }

        public Widgets.Note make_item (MainWindow win, GLib.Object item) {
            lv.is_modified = true;
            return new Widgets.Note (this, (Log) item);
        }

        public void make_note (string title, string subtitle, string text, string color, string notebook, bool pinned) {
            var log = new Log ();
            log.title = title;
            log.subtitle = subtitle;
            log.text = text;
            log.color = color;
            log.notebook = notebook;
            log.pinned = pinned;

            lv.is_modified = true;

            notestore.insert_sorted(log, (a, b) => {
                if (((Log)a).pinned) {
                    return -1;
                }

                return 0;
            });
        }

        public Widgets.TrashedNote make_trash_item (MainWindow win, GLib.Object titem) {
            tv.is_modified = true;
            return new Widgets.TrashedNote (this, (TrashLog) titem);
        }

        public void make_trash_note (string title, string subtitle, string text, string color, string notebook) {
            var tlog = new TrashLog ();
            tlog.title = title;
            tlog.subtitle = subtitle;
            tlog.text = text;
            tlog.color = color;
            tlog.notebook = notebook;
            tv.is_modified = true;

            trashstore.append(tlog);
        }

        public void make_notebook (string title) {
            var nb = new Notebook ();
            nb.title = title;

            notebookstore.append(nb);
        }

        public async void on_create_new () {
            var dt = new GLib.DateTime.now_local ();
            var log = new Log ();

            uid++;

            log.title = _("New Note ") + (@"$uid");
            log.subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M"));
            log.text = "";
            log.color = "#ebebeb";
            log.notebook = "<i>" + _("No Notebook") + "</i>";
            log.pinned = false;

            notestore.insert_sorted(log, (a, b) => {
                if (((Log)a).pinned) {
                    return -1;
                }

                return 0;
            });

            lv.is_modified = true;

            if (listview.get_selected_row () == null) {
                main_stack.set_visible_child (empty_state);
            }
            settingmenu.visible = true;

            tm.save_notes.begin (notestore);
        }

        public void select_notebook (GLib.SimpleAction action, GLib.Variant? parameter) {
            hbb.title = parameter.get_string ();
            lv.set_selected_notebook (parameter.get_string ());
            sidebar_stack.set_visible_child (list_scroller);

            main_stack.set_visible_child (empty_state);
            if (listview.get_selected_row () != null) {
                listview.unselect_row(listview.get_selected_row ());
            }
            settingmenu.visible = false;
        }

        public void action_about () {
            const string COPYRIGHT = "Copyright \xc2\xa9 2017-2021 Paulo \"Lains\" Galardi\n";

            const string? AUTHORS[] = {
                "Paulo \"Lains\" Galardi",
                null
            };

            var program_name = Config.NAME_PREFIX + _("Notejot");
            Gtk.show_about_dialog (this,
                                   "program-name", program_name,
                                   "logo-icon-name", Config.APP_ID,
                                   "version", Config.VERSION,
                                   "comments", _("Jot your ideas."),
                                   "copyright", COPYRIGHT,
                                   "authors", AUTHORS,
                                   "artists", null,
                                   "license-type", Gtk.License.GPL_3_0,
                                   "wrap-license", false,
                                   "translator-credits", _("translator-credits"),
                                   null);
        }

        public void action_new_note () {
            on_create_new.begin ();
        }

        public void action_all_notes () {
            sidebar_stack.set_visible_child (list_scroller);
            Notejot.Application.gsettings.set_string("last-view", "list");
            hbb.title = (_("All Notes"));
            main_stack.set_visible_child (empty_state);

            uint lvu = lv.last_uid;
            titlebar.get_style_context ().add_class ("notejot-empty-title");
            titlebar.get_style_context ().remove_class (@"notejot-action-$lvu");
            if (listview.get_selected_row () != null) {
                listview.unselect_row(listview.get_selected_row ());
            }
            settingmenu.visible = false;

            var sbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/note_menu.ui");
            var smenu = (Menu)sbuilder.get_object ("smenu");

            settingmenu.menu_model = smenu;

            var popover = settingmenu.get_popover ();
            popover.add_child (sbuilder, sm.nmp, "theme");
            lv.set_selected_notebook ("");
        }

        public void action_trash () {
            sidebar_stack.set_visible_child (trash_scroller);
            Notejot.Application.gsettings.set_string("last-view", "trash");
            hbb.title = (_("Trash"));
            main_stack.set_visible_child (empty_state);

            uint lvu = lv.last_uid;
            titlebar.get_style_context ().add_class ("notejot-empty-title");
            titlebar.get_style_context ().remove_class (@"notejot-action-$lvu");
            if (trashview.get_selected_row () != null) {
                trashview.unselect_row(trashview.get_selected_row ());
            }
            settingmenu.visible = false;
        }

        public void action_trash_notes () {
            var dialog = new Gtk.MessageDialog (this, 0, 0, 0, null);
            dialog.modal = true;

            dialog.set_title (_("Empty the Trashed Notes?"));
            dialog.text = (_("Emptying the trash means all the notes in it will be permanently lost with no recovery."));

            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            dialog.add_button (_("Empty Trash"), Gtk.ResponseType.OK);

            dialog.response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.OK:
                        trashstore.remove_all ();
                        dialog.close ();
                        break;
                    case Gtk.ResponseType.NO:
                        dialog.close ();
                        break;
                    case Gtk.ResponseType.CANCEL:
                    case Gtk.ResponseType.CLOSE:
                    case Gtk.ResponseType.DELETE_EVENT:
                        dialog.close ();
                        return;
                    default:
                        assert_not_reached ();
                }
            });

            if (dialog != null) {
                dialog.present ();
                return;
            } else {
                dialog.show ();
            }
        }

        public void action_keys () {
            try {
                var build = new Gtk.Builder ();
                build.add_from_resource ("/io/github/lainsce/Notejot/shortcuts.ui");
                var window =  (Gtk.ShortcutsWindow) build.get_object ("shortcuts-notejot");
                window.set_transient_for (this);
                window.show ();
            } catch (Error e) {
                warning ("Failed to open shortcuts window: %s\n", e.message);
            }
        }

        public void action_move_to () {
            var move_to_dialog = new Widgets.MoveToDialog (this);
            move_to_dialog.show ();
        }

        public void action_pin_note () {
            Gtk.ListBoxRow row = listview.get_selected_row ();

            if (row != null) {
                if (!((Widgets.Note)row).log.pinned) {
                    var tlog = new Log ();
                    tlog.title = ((Widgets.Note)row).log.title;
                    tlog.subtitle = ((Widgets.Note)row).log.subtitle;
                    tlog.text = ((Widgets.Note)row).log.text;
                    tlog.color = ((Widgets.Note)row).log.color;
                    tlog.notebook = ((Widgets.Note)row).log.notebook;
                    tlog.pinned = true;
	                notestore.insert_sorted(tlog, (a, b) => {
                        ((Widgets.Note)row).picon.set_visible (true);
                        return -1;
                    });

                    uint pos;
                    notestore.find (((Widgets.Note)row).log, out pos);
                    notestore.remove (pos);
	                ((Widgets.Note)row).picon.set_visible (true);
	                tm.save_notes.begin (notestore);
                } else {
                    var tlog = new Log ();
                    tlog.title = ((Widgets.Note)row).log.title;
                    tlog.subtitle = ((Widgets.Note)row).log.subtitle;
                    tlog.text = ((Widgets.Note)row).log.text;
                    tlog.color = ((Widgets.Note)row).log.color;
                    tlog.notebook = ((Widgets.Note)row).log.notebook;
                    tlog.pinned = false;
	                notestore.insert_sorted(tlog, (a, b) => {
                        ((Widgets.Note)row).picon.set_visible (false);
                        return -1;
                    });

                    uint pos;
                    notestore.find (((Widgets.Note)row).log, out pos);
                    notestore.remove (pos);
	                tm.save_notes.begin (notestore);
                }
            }
        }

        public void action_delete_note () {
            Gtk.ListBoxRow row;

            row = listview.get_selected_row ();

            // Reset titlebar color
            ((Widgets.Note)row).update_theme("#ebebeb");

            if (row != null) {
                var tlog = new TrashLog ();
                tlog.title = ((Widgets.Note)row).log.title;
                tlog.subtitle = ((Widgets.Note)row).log.subtitle;
                tlog.text = ((Widgets.Note)row).log.text;
                tlog.color = ((Widgets.Note)row).log.color;
                tlog.notebook = ((Widgets.Note)row).log.notebook;
                tlog.pinned = ((Widgets.Note)row).log.pinned;
	            trashstore.append (tlog);

	            var rowd = main_stack.get_child_by_name ("textfield-%d".printf(((Widgets.Note)row).uid));
                main_stack.remove (rowd);

                uint pos;
                notestore.find (((Widgets.Note)row).log, out pos);
                notestore.remove (pos);
            }

            main_stack.set_visible_child (empty_state);

            if (leaflet.get_visible_child () != sgrid) {
                leaflet.set_visible_child (sgrid);
            }

            uint lvu = lv.last_uid;
            settingmenu.visible = false;
            titlebar.get_style_context ().add_class ("notejot-empty-title");
            titlebar.get_style_context ().remove_class (@"notejot-action-$lvu");
        }

        public void action_restore_note () {
            Gtk.ListBoxRow row;

            row = trashview.get_selected_row ();

            if (row != null) {
                var log = new Log ();
                log.title = ((Widgets.TrashedNote)row).tlog.title;
                log.subtitle = ((Widgets.TrashedNote)row).tlog.subtitle;
                log.text = ((Widgets.TrashedNote)row).tlog.text;
                log.color = ((Widgets.TrashedNote)row).tlog.color;
                log.notebook = ((Widgets.TrashedNote)row).tlog.notebook;
	            notestore.append (log);

	            var rowd = main_stack.get_child_by_name ("textfield-trash-%d".printf(((Widgets.TrashedNote)row).tuid));
                main_stack.remove (rowd);

                uint pos;
                trashstore.find (((Widgets.TrashedNote)row).tlog, out pos);
                trashstore.remove (pos);
            }

            main_stack.set_visible_child (empty_state);

            if (leaflet.get_visible_child () != sgrid) {
                leaflet.set_visible_child (sgrid);
            }
        }

        public void action_edit_notebooks () {
            var edit_nb_dialog = new Widgets.EditNotebooksDialog (this);
            edit_nb_dialog.show ();
        }

        private void erase_utf8 (StringBuilder builder, ssize_t start, ssize_t len) {
            // erase a range in a string with respect to special offsets
            // because of utf8
            int real_start = builder.str.index_of_nth_char(start);
            builder.erase(real_start, len);
        }

        private void extend_selection_to_format_block(Format? format = null) {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;

                Gtk.TextIter sel_start, sel_end;
                var text_buffer = textfield.get_buffer();
                text_buffer.get_selection_bounds (out sel_start, out sel_end);
                int start_rel, end_rel;
                string wrap;

                foreach (FormatBlock fmt in textfield.fmt_syntax_blocks()) {
                    if (format != null && fmt.format != format)
                        continue;

                    // after selection, nothing relevant anymore
                    if (fmt.start > sel_end.get_offset())
                        break;

                    // before selection, not relevant
                    if (fmt.end < sel_start.get_offset())
                        continue;

                    start_rel = sel_start.get_offset() - fmt.start;
                    end_rel = fmt.end - sel_end.get_offset();

                    wrap = format_to_string(fmt.format);

                    if (start_rel > 0 && start_rel <= wrap.length) {
                        // selection start does not (entirely) cover the formatters
                        // only touches them -> extend selection
                        sel_start.set_offset(fmt.start);
                    }

                    if (end_rel > 0 && end_rel <= wrap.length) {
                        // selection end does not (entirely) cover the formatters
                        // only touches them -> extend selection
                        sel_end.set_offset(fmt.end);
                    }
                }

                text_buffer.select_range(sel_start, sel_end);
            }
        }

        public void action_normal () {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;

                Gtk.TextIter sel_start, sel_end;
                int offset = 0, fmt_start, fmt_end;
                int move_forward = 0, move_backward = 0;
                string wrap = "";

                var text_buffer = textfield.get_buffer ();

                // only record a single user action for the entire function
                text_buffer.begin_user_action();
                // ensure the selection is correctly extended
                extend_selection_to_format_block ();

                text_buffer.get_selection_bounds (out sel_start, out sel_end);

                var text = textfield.get_selected_text ();

                var text_builder = new StringBuilder(text);

                foreach (FormatBlock fmt in textfield.fmt_syntax_blocks()) {
                    // after selection, nothing relevant anymore
                    if (fmt.start > sel_end.get_offset() - 1)
                        break;

                    // before selection, not relevant
                    if (fmt.end - 1 < sel_start.get_offset())
                        continue;

                    // relative to selected text
                    fmt_start = fmt.start - sel_start.get_offset();
                    fmt_end = fmt.end - sel_start.get_offset();

                    wrap = format_to_string(fmt.format);

                    if (fmt_start >= 0) {
                        // format block starts within selection -> remove starting wrap
                        erase_utf8 (text_builder, fmt_start + offset, wrap.length);
                        offset -= wrap.length;
                    } else {
                        // selection starts within format block -> add ending wrap
                        text_builder.prepend (wrap);
                        offset += wrap.length;
                        // added wrap character before selection,
                        // should be ignored for new selection
                        move_forward = wrap.length;
                    }

                    if (fmt_end <= text.char_count()) {
                        // format block ends within selection
                        erase_utf8 (text_builder, fmt_end + offset - wrap.length, wrap.length);
                        offset -= wrap.length;
                    } else {
                        // selection ends within format block -> add starting wrap
                        text_builder.append(wrap);
                        offset += wrap.length;
                        // added wrap character after selection,
                        // should be ignored for new selection
                        move_backward = wrap.length;
                    }
                }

                text = text_builder.str;

                text_buffer.delete (ref sel_start, ref sel_end);
                text_buffer.insert (ref sel_start, text, -1);
                // text length without potential wrap characters at the beginning or the end
                int select_text_length = text.char_count() - (move_backward + move_forward);
                select_text(textfield, move_backward, select_text_length);
                text_buffer.end_user_action ();

                textfield.grab_focus ();
            }
        }

        public void action_bold () {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;
                text_wrap(textfield, "|", _("bold text"));
            }
        }

        public void action_italic () {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;
                text_wrap(textfield, "*", _("italic text"));
            }
        }

        public void action_ul () {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;
                text_wrap(textfield, "_", _("underline text"));
            }
        }

        public void action_s () {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;
                text_wrap(textfield, "~", _("strikethrough text"));
            }
        }

        public void action_item () {
            if (((Widgets.Note) listview.get_selected_row ()) != null) {
                var textfield = ((Widgets.Note) listview.get_selected_row ()).textfield;
                insert_item(textfield, _("Item"));
            }
        }

        public void text_wrap(Gtk.TextView text_view, string wrap, string helptext) {
            extend_selection_to_format_block(string_to_format(wrap));

            var text_buffer = text_view.get_buffer();
            string text;
            int move_back = 0, text_length = 0;
            Gtk.TextIter start, end;
            text_buffer.get_selection_bounds(out start, out end);

            if (text_buffer.get_has_selection()) {
                // Find current highlighting
                text = text_buffer.get_text(start, end, true);

                text_length = text.length;
                text = text.chug();
                // move to stripped start
                start.forward_chars(text_length - text.length);

                text_length = text.length;
                text = text.chomp();
                // move to stripped end
                end.backward_chars(text_length - text.length);

                // adjust selection to stripped text
                text_buffer.select_range(start, end);

                if (text.has_prefix(wrap) && text.has_suffix(wrap)){
                    // formatting is already in place
                    text = text[wrap.length:-wrap.length];
                    text_length = text.length;
                } else {
                    // store the text length of the original string
                    text_length = text.length;
                    text = wrap + text + wrap;
                    move_back = wrap.length;
                }
                // only record a single action instead of two
                text_buffer.begin_user_action();
                text_buffer.delete(ref start, ref end);
                text_buffer.insert(ref start, text, -1);
                text_buffer.end_user_action();
            } else {
                text_buffer.insert(ref start, wrap + helptext + wrap, -1);
                text_length = helptext.length;
                move_back = wrap.length;
            }

            select_text(text_view, move_back, text_length);
            text_view.grab_focus();
        }

        public void insert_item (Gtk.TextView text_view, string helptext) {
            var text_buffer = text_view.get_buffer();
            string text;
            int text_length = 0;
            Gtk.TextIter start, end, cursor_iter;
            text_buffer.get_selection_bounds(out start, out end);

            if (text_buffer.get_has_selection()) {
                if (start.starts_line()){
                    text = text_buffer.get_text(start, end, false);
                    if (text.has_prefix("- ")){
                        var delete_end = start.copy();
                        delete_end.forward_chars(2);
                        text_buffer.delete(ref start, ref delete_end);
                    } else {
                        text_buffer.insert(ref start, "- ", -1);
                    }
                }
            } else {
                helptext = _("Item");
                text_length = helptext.length;

                var cursor_mark = text_buffer.get_insert();
                text_buffer.get_iter_at_mark(out cursor_iter, cursor_mark);

                var start_ext = cursor_iter.copy();
                start_ext.backward_lines(3);
                text = text_buffer.get_text(cursor_iter, start_ext, false);
                var lines = text.split("\n");

                foreach (var line in lines) {
                    if (line != null && line.has_prefix("- ")) {
                        if (cursor_iter.starts_line()) {
                            text_buffer.insert_at_cursor(line[:2] + helptext, -1);
                        } else {
                            text_buffer.insert_at_cursor("\n" + line[:2] + helptext, -1);
                        }
                        break;
                    } else {
                        if (lines[-1] != null && lines[-2] != null) {
                            text_buffer.insert_at_cursor("- " + helptext, -1);
                        } else if (lines[-1] != null) {
                            if (cursor_iter.starts_line()){
                                text_buffer.insert_at_cursor("- " + helptext, -1);
                            } else {
                                text_buffer.insert_at_cursor("\n- " + helptext, -1);
                            }
                        } else {
                            text_buffer.insert_at_cursor("\n\n- " + helptext, -1);
                        }
                        break;
                    }
                }

                select_text(text_view, 0, text_length);
            }
            text_view.grab_focus();
        }

        public void select_text (Gtk.TextView text_view, int offset, int length) {
            var text_buffer = text_view.get_buffer();
            var cursor_mark = text_buffer.get_insert();
            Gtk.TextIter cursor_iter;

            text_buffer.get_iter_at_mark(out cursor_iter, cursor_mark);
            cursor_iter.backward_chars(offset);
            text_buffer.move_mark_by_name("selection_bound", cursor_iter);
            cursor_iter.backward_chars(length);
            text_buffer.move_mark_by_name("insert", cursor_iter);
        }
    }
}
