/*
 * Copyright (C) 2017-2022 Lains
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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/trashcontentview.ui")]
public class Notejot.TrashContentView : View {
    delegate void HookFunc ();
    public signal void clicked ();

    [GtkChild]
    public unowned Gtk.Box main_box;
    [GtkChild]
    public unowned Gtk.Button back_button;
    [GtkChild]
    public unowned Gtk.Stack stack;
    [GtkChild]
    public unowned Gtk.Box trash_view;
    [GtkChild]
    public unowned Gtk.Box empty_view;
    [GtkChild]
    public unowned Gtk.Button s_menu;
    [GtkChild]
    unowned Gtk.Label trash_title;
    [GtkChild]
    unowned Gtk.Label trash_subtitle;
    [GtkChild]
    unowned Gtk.Label notebook_subtitle;
    [GtkChild]
    public unowned Gtk.TextView trash_textbox;
    [GtkChild]
    unowned Gtk.TextBuffer trash_text;
    [GtkChild]
    unowned Gtk.TextTag bold_font;
    [GtkChild]
    unowned Gtk.TextTag italic_font;
    [GtkChild]
    unowned Gtk.TextTag ul_font;
    [GtkChild]
    unowned Gtk.TextTag s_font;
    [GtkChild]
    public new unowned Adw.HeaderBar titlebar;
    [GtkChild]
    unowned Adw.StatusPage trash_status_page;

    Binding ? bb_binding;
    Binding ? title_binding;
    Binding ? subtitle_binding;
    Binding ? notebook_binding;
    Binding ? text_binding;

    private Gtk.CssProvider provider = new Gtk.CssProvider ();
    public TrashViewModel ? vm { get; set; }
    public NotebookViewModel ? nvm { get; set; }
    public MainWindow ? win { get; set; }
    public Gtk.PopoverMenu ? pop;
    uint update_idle_source = 0;

    Trash ? _trash;
    public Trash ? trash {
        get { return _trash; }
        set {
            if (value == _trash)
                return;

            title_binding ? .unbind ();
            subtitle_binding ? .unbind ();
            notebook_binding ? .unbind ();
            text_binding ? .unbind ();

            _trash = value;

            fmt_syntax_start ();
            main_box.get_style_context ().add_provider (provider, 1);

            s_menu.visible = _trash != null ? true : false;
            stack.visible_child = _trash != null ? (Gtk.Widget) trash_view : empty_view;

            title_binding = _trash ? .bind_property ("title", trash_title, "label", SYNC_CREATE | BIDIRECTIONAL);
            subtitle_binding = _trash ? .bind_property ("subtitle", trash_subtitle, "label", SYNC_CREATE | BIDIRECTIONAL);
            notebook_binding = _trash ? .bind_property ("notebook", notebook_subtitle, "label", SYNC_CREATE | BIDIRECTIONAL);
            text_binding = _trash ? .bind_property ("text", trash_text, "text", SYNC_CREATE | BIDIRECTIONAL);

            var settings = new Settings ();
            switch (settings.font_size) {
            case "'small'":
                trash_textbox.add_css_class ("sml-font");
                trash_textbox.remove_css_class ("med-font");
                trash_textbox.remove_css_class ("big-font");
                break;
            default:
            case "'medium'":
                trash_textbox.remove_css_class ("sml-font");
                trash_textbox.add_css_class ("med-font");
                trash_textbox.remove_css_class ("big-font");
                break;
            case "'large'":
                trash_textbox.remove_css_class ("sml-font");
                trash_textbox.remove_css_class ("med-font");
                trash_textbox.add_css_class ("big-font");
                break;
            }
            settings.notify["font-size"].connect (() => {
                switch (settings.font_size) {
                    case "'small'":
                        trash_textbox.add_css_class ("sml-font");
                        trash_textbox.remove_css_class ("med-font");
                        trash_textbox.remove_css_class ("big-font");
                        break;
                    default:
                    case "'medium'":
                        trash_textbox.remove_css_class ("sml-font");
                        trash_textbox.add_css_class ("med-font");
                        trash_textbox.remove_css_class ("big-font");
                        break;
                    case "'large'":
                        trash_textbox.remove_css_class ("sml-font");
                        trash_textbox.remove_css_class ("med-font");
                        trash_textbox.add_css_class ("big-font");
                        break;
                }
            });

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf (_trash.color));

            vm.update_trash_color (_trash, _trash.color);

            // TrashView Back Button
            bb_binding = ((Adw.Leaflet) MiscUtils.find_ancestor_of_type<Adw.Leaflet> (this)).bind_property ("folded", back_button, "visible", SYNC_CREATE);
            back_button.clicked.connect (() => {
                ((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow> (this)).leaf.set_visible_child (((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow> (this)).sgrid);
            });
        }
    }

    public TrashContentView (TrashViewModel ? vm) {
        Object (
            vm: vm
        );
    }

    construct {
        fmt_syntax_start ();

        main_box.get_style_context ().add_provider (provider, 1);

        Timeout.add_seconds (1, () => {
            if (vm.trashs.get_n_items () == 1) {
                trash_status_page.set_title (_ ("Trash has") + " " + vm.trashs.get_n_items ().to_string () + " " + _ ("Note"));
            } else if (vm.trashs.get_n_items () >= 0) {
                trash_status_page.set_title (_ ("Trash has") + " " + vm.trashs.get_n_items ().to_string () + " " + _ ("Notes"));
            } else {
                trash_status_page.set_title (_ ("Trash is Empty"));
            }
            return false;
        });
    }

    public signal void trash_update_requested (Trash trash);
    public signal void trash_restore_requested (Trash trash);

    [GtkCallback]
    void on_trash_restore_requested () {
        trash_restore_requested (trash);
    }

    public void fmt_syntax_start () {
        if (update_idle_source > 0) {
            GLib.Source.remove (update_idle_source);
        }

        update_idle_source = GLib.Idle.add (() => {
            var text_buffer = trash_textbox.get_buffer ();
            fmt_syntax (text_buffer);
            return false;
        });
    }

    public bool fmt_syntax (Gtk.TextBuffer buffer) {
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

    public void extend_selection_to_format_block (Gtk.TextView text_view, Format ? format = null) {
        Gtk.TextIter sel_start, sel_end;
        var text_buffer = text_view.get_buffer ();
        text_buffer.get_selection_bounds (out sel_start, out sel_end);
        int start_rel, end_rel;
        string wrap;

        foreach (FormatBlock fmt in fmt_syntax_blocks (text_buffer)) {
            if (format != null && fmt.format != format)
                continue;

            // after selection, nothing relevant anymore
            if (fmt.start > sel_end.get_offset ())
                break;

            // before selection, not relevant
            if (fmt.end < sel_start.get_offset ())
                continue;

            start_rel = sel_start.get_offset () - fmt.start;
            end_rel = fmt.end - sel_end.get_offset ();

            wrap = format_to_string (fmt.format);

            if (start_rel > 0 && start_rel <= wrap.length) {
                // selection start does not (entirely) cover the formatters
                // only touches them -> extend selection
                sel_start.set_offset (fmt.start);
            }

            if (end_rel > 0 && end_rel <= wrap.length) {
                // selection end does not (entirely) cover the formatters
                // only touches them -> extend selection
                sel_end.set_offset (fmt.end);
            }
        }

        text_buffer.select_range (sel_start, sel_end);
    }

    public void text_wrap (Gtk.TextView text_view, string wrap, string helptext) {
        extend_selection_to_format_block (text_view, string_to_format (wrap));

        var text_buffer = text_view.get_buffer ();
        string text;
        int move_back = 0, text_length = 0;
        Gtk.TextIter start, end;
        text_buffer.get_selection_bounds (out start, out end);

        if (text_buffer.get_has_selection ()) {
            // Find current highlighting
            text = text_buffer.get_text (start, end, true);

            text_length = text.length;
            text = text.chug ();
            // move to stripped start
            start.forward_chars (text_length - text.length);

            text_length = text.length;
            text = text.chomp ();
            // move to stripped end
            end.backward_chars (text_length - text.length);

            // adjust selection to stripped text
            text_buffer.select_range (start, end);

            if (text.has_prefix (wrap) && text.has_suffix (wrap)) {
                // formatting is already in place
                text = text[wrap.length : -wrap.length];
                text_length = text.length;
            } else {
                // store the text length of the original string
                text_length = text.length;
                text = wrap + text + wrap;
                move_back = wrap.length;
            }
            // only record a single action instead of two
            text_buffer.begin_user_action ();
            text_buffer.delete (ref start, ref end);
            text_buffer.insert (ref start, text, -1);
            text_buffer.end_user_action ();
        } else {
            text_buffer.insert (ref start, wrap + helptext + wrap, -1);
            text_length = helptext.length;
            move_back = wrap.length;
        }

        select_text (text_view, move_back, text_length);
        text_view.grab_focus ();
    }

    public void insert_item (Gtk.TextView text_view, string helptext) {
        var text_buffer = text_view.get_buffer ();
        string text;
        int text_length = 0;
        Gtk.TextIter start, end, cursor_iter;
        text_buffer.get_selection_bounds (out start, out end);

        if (text_buffer.get_has_selection ()) {
            if (start.starts_line ()) {
                text = text_buffer.get_text (start, end, false);
                if (text.has_prefix ("- ")) {
                    var delete_end = start.copy ();
                    delete_end.forward_chars (2);
                    text_buffer.delete (ref start, ref delete_end);
                } else {
                    text_buffer.insert (ref start, "- ", -1);
                }
            }
        } else {
            helptext = _ ("Item");
            text_length = helptext.length;

            var cursor_mark = text_buffer.get_insert ();
            text_buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

            var start_ext = cursor_iter.copy ();
            start_ext.backward_lines (3);
            text = text_buffer.get_text (cursor_iter, start_ext, false);
            var lines = text.split ("\n");

            foreach (var line in lines) {
                if (line != null && line.has_prefix ("- ")) {
                    if (cursor_iter.starts_line ()) {
                        text_buffer.insert_at_cursor (line[: 2] + helptext, -1);
                    } else {
                        text_buffer.insert_at_cursor ("\n" + line[: 2] + helptext, -1);
                    }
                    break;
                } else {
                    if (lines[-1] != null && lines[-2] != null) {
                        text_buffer.insert_at_cursor ("- " + helptext, -1);
                    } else if (lines[-1] != null) {
                        if (cursor_iter.starts_line ()) {
                            text_buffer.insert_at_cursor ("- " + helptext, -1);
                        } else {
                            text_buffer.insert_at_cursor ("\n- " + helptext, -1);
                        }
                    } else {
                        text_buffer.insert_at_cursor ("\n\n- " + helptext, -1);
                    }
                    break;
                }
            }

            select_text (text_view, 0, text_length);
        }
        text_view.grab_focus ();
    }

    public void select_text (Gtk.TextView text_view, int offset, int length) {
        var text_buffer = text_view.get_buffer ();
        var cursor_mark = text_buffer.get_insert ();
        Gtk.TextIter cursor_iter;

        text_buffer.get_iter_at_mark (out cursor_iter, cursor_mark);
        cursor_iter.backward_chars (offset);
        text_buffer.move_mark_by_name ("selection_bound", cursor_iter);
        cursor_iter.backward_chars (length);
        text_buffer.move_mark_by_name ("insert", cursor_iter);
    }

    public FormatBlock[] fmt_syntax_blocks (Gtk.TextBuffer buffer) {
        Gtk.TextIter start, end;
        int match_start_offset, match_end_offset;
        FormatBlock[] format_blocks = {};

        GLib.MatchInfo match;

        buffer.get_bounds (out start, out end);
        string measure_text, buf = buffer.get_text (start, end, true);

        try {
            var regex = new Regex ("""(?s)(?<wrap>[|*_~]).*\g{wrap}""");

            if (regex.match (buf, 0, out match)) {
                do {
                    if (match.fetch_pos (0, out match_start_offset, out match_end_offset)) {
                        // measure the offset of the actual unicode glyphs,
                        // not the byte offset
                        measure_text = buf[0 : match_start_offset];
                        match_start_offset = measure_text.char_count ();
                        measure_text = buf[0 : match_end_offset];
                        match_end_offset = measure_text.char_count ();

                        Format format = string_to_format (match.fetch_named ("wrap"));

                        format_blocks += FormatBlock () {
                            start = match_start_offset,
                            end = match_end_offset,
                            format = format
                        };
                    }
                } while (match.next ());
            }
        } catch (GLib.RegexError re) {
            warning ("%s".printf (re.message));
        }

        return format_blocks;
    }

    public string get_selected_text (Gtk.TextBuffer buffer) {
        Gtk.TextIter A;
        Gtk.TextIter B;
        if (buffer.get_selection_bounds (out A, out B)) {
            return buffer.get_text (A, B, true);
        }

        return "";
    }
}