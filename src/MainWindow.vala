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
        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.Button new_button;
        [GtkChild]
        public unowned Gtk.Button back_button;
        [GtkChild]
        public unowned Gtk.MenuButton menu_button;
        [GtkChild]
        public unowned Gtk.SearchEntry note_search;

        [GtkChild]
        public unowned Gtk.Box grid;
        [GtkChild]
        public unowned Gtk.Box sgrid;
        [GtkChild]
        public unowned Adw.Leaflet leaflet;
        [GtkChild]
        public unowned Gtk.Overlay list_scroller;
        [GtkChild]
        public unowned Gtk.Overlay trash_scroller;
        [GtkChild]
        public unowned Notejot.LogListView listview;
        [GtkChild]
        public unowned Gtk.ListBox trashview;

        [GtkChild]
        public unowned Gtk.Box main_box;
        [GtkChild]
        public unowned Gtk.Stack sidebar_stack;
        [GtkChild]
        public new unowned Adw.HeaderBar titlebar;
        [GtkChild]
        public unowned Adw.HeaderBar stitlebar;

        // Custom
        public TaskManager tm;
        public LogListView view_list;
        public LogContentView view_content;

        // Etc
        uint update_idle_source = 0;
        public Gtk.Settings gtk_settings;
        private Gtk.TextTag bold_font;
        private Gtk.TextTag italic_font;
        private Gtk.TextTag ul_font;
        private Gtk.TextTag s_font;

        public LogViewModel view_model { get; construct; }

        public GLib.ListStore notebookstore;

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ABOUT = "action_about";
        public const string ACTION_NEW_NOTE = "action_new_note";
        public const string ACTION_KEYS = "action_keys";
        public const string ACTION_MOVE_TO = "action_move_to";
        public const string ACTION_EDIT_NOTEBOOKS = "action_edit_notebooks";

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
              {ACTION_KEYS, action_keys},
              {ACTION_MOVE_TO, action_move_to},
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},

              {ACTION_NORMAL, action_normal },
              {ACTION_BOLD, action_bold},
              {ACTION_ITALIC, action_italic},
              {ACTION_UL, action_ul},
              {ACTION_S, action_s},
              {ACTION_ITEM, action_item},
        };

        public Adw.Application app { get; construct; }
        public MainWindow (Adw.Application application, LogViewModel view_model) {
            GLib.Object (
                application: application,
                app: application,
                view_model: view_model,
                icon_name: Config.APP_ID,
                title: "Notejot"
            );
        }

        construct {
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
            app.set_accels_for_action ("win.action_keys", {"<Ctrl>question"});

            app.set_accels_for_action ("win.action_normal", {"<Ctrl>t"});
            app.set_accels_for_action ("win.action_bold", {"<Ctrl>b"});
            app.set_accels_for_action ("win.action_italic", {"<Ctrl>i"});
            app.set_accels_for_action ("win.action_ul", {"<Ctrl>u"});
            app.set_accels_for_action ("win.action_s", {"<Ctrl><Shift>s"});

            // Main View
            tm = new TaskManager (this);

            back_button.clicked.connect (() => {
                leaflet.set_visible_child (sgrid);
            });

            var builder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/menu.ui");
            menu_button.menu_model = (MenuModel)builder.get_object ("menu");

            notebookstore = new GLib.ListStore (typeof (Notebook));
            notebookstore.items_changed.connect ((pos, add, rm) => {
                tm.save_notebooks.begin (notebookstore);
            });

            Timeout.add_seconds(1, () => {
                tm.save_notebooks.begin (notebookstore);
            });

            // Preparing window to be shown
            var settings = new Settings ();
            set_default_size(
                settings.window_w,
                settings.window_h
            );
            if (settings.is_maximized)
                maximize ();

            var action_fontsize = settings.create_action ("font-size");
            app.add_action(action_fontsize);

            this.show ();

            load_all_notes ();
        }

        protected override bool close_request () {
            debug ("Exiting window... Disposing of stuff...");
            var settings = new Settings ();
            settings.is_maximized = is_maximized ();

            if (!is_maximized()) {
                settings.window_w = get_width ();
                settings.window_h = get_height ();
            }

            this.dispose ();
            return true;
        }

        // IO?
        public void load_all_notes () {
            tm.load_from_file_nb.begin ();
        }

        [GtkCallback]
        void on_new_note_requested () {
            view_model.create_new_note (this);
        }

        [GtkCallback]
        void on_display_note_requested () {
            leaflet.set_visible_child (grid);
        }

        [GtkCallback]
        public void on_note_update_requested (Log note) {
            view_model.update_note (note);
        }

        [GtkCallback]
        public void on_note_removal_requested (Log note) {
            view_model.delete_note (note, this);
        }

        public MainWindow get_instance () {
            return this;
        }

        public Adw.ActionRow make_nb_item (MainWindow win, GLib.Object item) {
            var actionrow = new Adw.ActionRow ();
            actionrow.get_style_context ().add_class ("content-sidebar-notebooks-item");
            actionrow.set_title ((((Notebook)item).title));

            var notebookicon = new Gtk.Image.from_icon_name ("notebook-symbolic");
            notebookicon.halign = Gtk.Align.START;
            notebookicon.valign = Gtk.Align.CENTER;

            actionrow.add_prefix (notebookicon);
            return actionrow;
        }

        public void make_notebook (string title) {
            var nb = new Notebook ();
            nb.title = title;

            notebookstore.append(nb);
        }

        public void action_about () {
            const string COPYRIGHT = "Copyright \xc2\xa9 2017-2021 Paulo \"Lains\" Galardi\n";

            const string? AUTHORS[] = {
                "Paulo \"Lains\" Galardi",
                null
            };

            var program_name = Config.NAME_PREFIX + "Notejot";
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
            view_model.create_new_note (this);
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
            var selected_row = view_list.selected_note;
            if (selected_row != null) {
                var textfield = ((Gtk.TextView)view_content.lc.note_textbox);

                Gtk.TextIter sel_start, sel_end;
                var text_buffer = textfield.get_buffer();
                text_buffer.get_selection_bounds (out sel_start, out sel_end);
                int start_rel, end_rel;
                string wrap;

                foreach (FormatBlock fmt in fmt_syntax_blocks(textfield.get_buffer())) {
                    if (format != null && fmt.format != format)
                        continue;

                    //after selection, nothing relevant anymore
                    if (fmt.start > sel_end.get_offset())
                        break;

                    //before selection, not relevant
                    if (fmt.end < sel_start.get_offset())
                        continue;

                    start_rel = sel_start.get_offset() - fmt.start;
                    end_rel = fmt.end - sel_end.get_offset();

                    wrap = format_to_string(fmt.format);

                    if (start_rel > 0 && start_rel <= wrap.length) {
                        //selection start does not (entirely) cover the formatters
                        //only touches them -> extend selection
                        sel_start.set_offset(fmt.start);
                    }

                    if (end_rel > 0 && end_rel <= wrap.length) {
                        //selection end does not (entirely) cover the formatters
                        //only touches them -> extend selection
                        sel_end.set_offset(fmt.end);
                    }
                }

                text_buffer.select_range(sel_start, sel_end);
            }
        }

        public void action_normal () {
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            if (textfield != null) {
                Gtk.TextIter sel_start, sel_end;
                int offset = 0, fmt_start, fmt_end;
                int move_forward = 0, move_backward = 0;
                string wrap = "";

                var text_buffer = textfield.get_buffer ();

                //only record a single user action for the entire function
                text_buffer.begin_user_action();
                //ensure the selection is correctly extended
                extend_selection_to_format_block ();

                text_buffer.get_selection_bounds (out sel_start, out sel_end);

                var text = get_selected_text (text_buffer);

                var text_builder = new StringBuilder(text);

                foreach (FormatBlock fmt in fmt_syntax_blocks(text_buffer)) {
                    //after selection, nothing relevant anymore
                    if (fmt.start > sel_end.get_offset() - 1)
                        break;

                    //before selection, not relevant
                    if (fmt.end - 1 < sel_start.get_offset())
                        continue;

                    //relative to selected text
                    fmt_start = fmt.start - sel_start.get_offset();
                    fmt_end = fmt.end - sel_start.get_offset();

                    wrap = format_to_string(fmt.format);

                    if (fmt_start >= 0) {
                        //format block starts within selection -> remove starting wrap
                        erase_utf8 (text_builder, fmt_start + offset, wrap.length);
                        offset -= wrap.length;
                    } else {
                        //selection starts within format block -> add ending wrap
                        text_builder.prepend (wrap);
                        offset += wrap.length;
                        //added wrap character before selection,
                        //should be ignored for new selection
                        move_forward = wrap.length;
                    }

                    if (fmt_end <= text.char_count()) {
                        //format block ends within selection
                        erase_utf8 (text_builder, fmt_end + offset - wrap.length, wrap.length);
                        offset -= wrap.length;
                    } else {
                        //selection ends within format block -> add starting wrap
                        text_builder.append(wrap);
                        offset += wrap.length;
                        //added wrap character after selection,
                        //should be ignored for new selection
                        move_backward = wrap.length;
                    }
                }

                text = text_builder.str;

                text_buffer.delete (ref sel_start, ref sel_end);
                text_buffer.insert (ref sel_start, text, -1);
                //text length without potential wrap characters at the beginning or the end
                int select_text_length = text.char_count() - (move_backward + move_forward);
                select_text(textfield, move_backward, select_text_length);
                text_buffer.end_user_action ();

                textfield.grab_focus ();
            }
        }

        public void action_bold () {
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            if (textfield != null) {
                text_wrap(textfield, "|", _("bold text"));
            }
        }

        public void action_italic () {
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            if (textfield != null) {
                text_wrap(textfield, "*", _("italic text"));
            }
        }

        public void action_ul () {
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            if (textfield != null) {
                text_wrap(textfield, "_", _("underline text"));
            }
        }

        public void action_s () {
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            if (textfield != null) {
                text_wrap(textfield, "~", _("strikethrough text"));
            }
        }

        public void action_item () {
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            if (textfield != null) {
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
                //Find current highlighting
                text = text_buffer.get_text(start, end, true);

                text_length = text.length;
                text = text.chug();
                //move to stripped start
                start.forward_chars(text_length - text.length);

                text_length = text.length;
                text = text.chomp();
                //move to stripped end
                end.backward_chars(text_length - text.length);

                //adjust selection to stripped text
                text_buffer.select_range(start, end);

                if (text.has_prefix(wrap) && text.has_suffix(wrap)){
                    //formatting is already in place
                    text = text[wrap.length:-wrap.length];
                    text_length = text.length;
                } else {
                    //store the text length of the original string
                    text_length = text.length;
                    text = wrap + text + wrap;
                    move_back = wrap.length;
                }
                //only record a single action instead of two
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
            var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
            var text_buffer = textfield.get_buffer();
            var cursor_mark = text_buffer.get_insert();
            Gtk.TextIter cursor_iter;

            text_buffer.get_iter_at_mark(out cursor_iter, cursor_mark);
            cursor_iter.backward_chars(offset);
            text_buffer.move_mark_by_name("selection_bound", cursor_iter);
            cursor_iter.backward_chars(length);
            text_buffer.move_mark_by_name("insert", cursor_iter);
        }

        public void fmt_syntax_start () {
            if (update_idle_source > 0) {
                GLib.Source.remove (update_idle_source);
            }

            update_idle_source = GLib.Idle.add (() => {
                var textfield = ((Gtk.TextView)view_content.lc.note_textbox);
                var text_buffer = textfield.get_buffer();
                bold_font = text_buffer.create_tag("bold", "weight", Pango.Weight.BOLD);
                italic_font = text_buffer.create_tag("italic", "style", Pango.Style.ITALIC);
                ul_font = text_buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);
                s_font = text_buffer.create_tag("strike", "strikethrough", true);
                fmt_syntax (text_buffer);
                return false;
            });
        }

        public FormatBlock[] fmt_syntax_blocks(Gtk.TextBuffer buffer) {
            Gtk.TextIter start, end;
            int match_start_offset, match_end_offset;
            FormatBlock[] format_blocks = {};

            GLib.MatchInfo match;

            buffer.get_bounds(out start, out end);
            string measure_text, buf = buffer.get_text (start, end, true);

            try {
                var regex = new Regex("""(?s)(?<wrap>[|*_~]).*\g{wrap}""");

                if (regex.match (buf, 0, out match)) {
                    do {
                        if (match.fetch_pos (0, out match_start_offset, out match_end_offset)) {
                            // measure the offset of the actual unicode glyphs,
                            // not the byte offset
                            measure_text = buf[0:match_start_offset];
                            match_start_offset = measure_text.char_count();
                            measure_text = buf[0:match_end_offset];
                            match_end_offset = measure_text.char_count();

                            Format format = string_to_format(match.fetch_named("wrap"));

                            format_blocks += FormatBlock() {
                                start = match_start_offset,
                                end = match_end_offset,
                                format = format
                            };
                        }
                    } while (match.next());
                }
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }

            return format_blocks;
        }

        private bool fmt_syntax (Gtk.TextBuffer buffer) {
            Gtk.TextIter start, end, fmt_start, fmt_end;

            buffer.get_bounds (out start, out end);
            buffer.remove_all_tags (start, end);

            foreach (FormatBlock fmt in fmt_syntax_blocks (buffer)) {
                buffer.get_iter_at_offset (out fmt_start, fmt.start);
                buffer.get_iter_at_offset (out fmt_end, fmt.end);

                Gtk.TextTag tag = bold_font;
                switch (fmt.format) {
                    case Format.BOLD:
                        tag = bold_font;
                        break;
                    case Format.ITALIC:
                        tag = italic_font;
                        break;
                    case Format.STRIKETHROUGH:
                        tag = s_font;
                        break;
                    case Format.UNDERLINE:
                        tag = ul_font;
                        break;
                }

                buffer.apply_tag (tag, fmt_start, fmt_end);
            }

            update_idle_source = 0;
            return GLib.Source.REMOVE;
        }

        public string get_selected_text (Gtk.TextBuffer buffer) {
            Gtk.TextIter A;
            Gtk.TextIter B;
            if (buffer.get_selection_bounds (out A, out B)) {
               return buffer.get_text(A, B, true);
            }

            return "";
        }
    }
}
