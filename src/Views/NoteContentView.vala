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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notecontentview.ui")]
public class Notejot.NoteContentView : View {
    delegate void HookFunc ();
    public signal void clicked ();

    [GtkChild]
    public unowned Gtk.Box main_box;
    [GtkChild]
    public unowned Gtk.Stack stack;
    [GtkChild]
    public unowned Gtk.Box note_view;
    [GtkChild]
    public unowned Gtk.Box empty_view;
    [GtkChild]
    public unowned Gtk.MenuButton s_menu;
    [GtkChild]
    unowned Gtk.Box note_header;
    [GtkChild]
    unowned Gtk.Entry note_title;
    [GtkChild]
    unowned Gtk.Label note_subtitle;
    [GtkChild]
    unowned Gtk.Label notebook_subtitle;
    [GtkChild]
    public unowned Gtk.TextView note_textbox;
    [GtkChild]
    unowned Gtk.TextBuffer note_text;
    [GtkChild]
    unowned Gtk.Revealer format_revealer;
    [GtkChild]
    unowned Gtk.TextTag bold_font;
    [GtkChild]
    unowned Gtk.TextTag italic_font;
    [GtkChild]
    unowned Gtk.TextTag ul_font;
    [GtkChild]
    unowned Gtk.TextTag s_font;
    [GtkChild]
    public unowned Gtk.Button back_button;
    [GtkChild]
    public unowned Gtk.Button back2_button;
    [GtkChild]
    public new unowned Adw.HeaderBar titlebar;
    [GtkChild]
    unowned Gtk.Button image_button;
    [GtkChild]
    unowned Gtk.Button image_remove_button;
    [GtkChild]
    unowned Notejot.NotePicture image;

    Binding? title_binding;
    Binding? subtitle_binding;
    Binding? notebook_binding;
    Binding? text_binding;
    Binding? pix_binding;
    Binding? bb_binding;

    private Gtk.CssProvider provider = new Gtk.CssProvider();
    public NoteViewModel? vm {get; set;}
    public NotebookViewModel? nvm {get; set;}
    public MainWindow? win {get; set;}
    public Adw.Leaflet? leaflet {get; set;}
    public Gtk.PopoverMenu? pop;
    uint update_idle_source = 0;

    Note? _note;
    public Note? note {
        get { return _note; }
        set {
            if (value == _note)
            return;

            title_binding?.unbind ();
            subtitle_binding?.unbind ();
            notebook_binding?.unbind ();
            text_binding?.unbind ();
            pix_binding ? .unbind ();

            if (_note != null)
                _note.notify.disconnect (on_text_updated);

            _note = value;

            fmt_syntax_start ();
            main_box.get_style_context().add_provider(provider, 1);

            format_revealer.reveal_child = _note != null ? true : false;
            s_menu.visible = _note != null ? true : false;
            stack.visible_child = _note != null ? (Gtk.Widget) note_view : empty_view;
            image_remove_button.visible = image.file != "" ? true : false;
            image_button.visible = image.file != "" ? false : true;

            var nmp = new Widgets.NoteTheme (this, vm, nvm);

            nmp.note_pin_button.clicked.connect (() => {
                if (_note != null) {
                    if (!_note.pinned) {
                        _note.pinned = true;
                        vm.update_note (_note);
                    } else {
                        _note.pinned = false;
                        vm.update_note (_note);
                    }
                }
            });

            nmp.color_button_red.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #a51d2d;");
                    vm.update_note_color (_note, "#a51d2d");
                }
            });

            nmp.color_button_orange.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #c64600;");
                    vm.update_note_color (_note, "#c64600");
                }
            });

            nmp.color_button_yellow.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #e5a50a;");
                    vm.update_note_color (_note, "#e5a50a");
                }
            });

            nmp.color_button_green.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #26a269;");
                    vm.update_note_color (_note, "#26a269");
                }
            });

            nmp.color_button_blue.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #1a5fb4;");
                    vm.update_note_color (_note, "#1a5fb4");
                }
            });

            nmp.color_button_purple.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #613583;");
                    vm.update_note_color (_note, "#613583");
                }
            });

            nmp.color_button_brown.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #63452c;");
                    vm.update_note_color (_note, "#63452c");
                }
            });

            nmp.delete_button.clicked.connect (() => {
                if (_note != null) {
                    note_removal_requested (_note);
                    pop.closed ();
                }
            });

            nmp.export_button.clicked.connect (() => {
                if (_note != null) {
                    // Export note to file user chooses.
                    export_note.begin (vm, _note);
                    pop.closed ();
                }
            });

            nmp.color_button_reset.toggled.connect (() => {
                if (_note != null) {
                    provider.load_from_data ((uint8[]) "@define-color note_color #797775;");
                    vm.update_note_color (_note, "#797775");
                }
            });

            pop = (Gtk.PopoverMenu)s_menu.get_popover ();
            pop.add_child (nmp, "theme");

            note_text.changed.connect (() => {
                Timeout.add(60, () => {
                    var dt = new GLib.DateTime.now_local ();
                    _note.subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M"));
                    return false;
                });
            });

            title_binding = _note?.bind_property ("title", note_title, "text", SYNC_CREATE|BIDIRECTIONAL);
            subtitle_binding = _note?.bind_property ("subtitle", note_subtitle, "label", SYNC_CREATE|BIDIRECTIONAL);
            notebook_binding = _note?.bind_property ("notebook", notebook_subtitle, "label", SYNC_CREATE|BIDIRECTIONAL);
            text_binding = _note?.bind_property ("text", note_text, "text", SYNC_CREATE|BIDIRECTIONAL);
            pix_binding = _note ? .bind_property ("picture", image, "file", SYNC_CREATE | BIDIRECTIONAL);

            var settings = new Settings ();
            switch (settings.font_size) {
                case "'small'":
                note_textbox.add_css_class ("sml-font");
                note_textbox.remove_css_class ("med-font");
                note_textbox.remove_css_class ("big-font");
                break;
                default:
                case "'medium'":
                note_textbox.remove_css_class ("sml-font");
                note_textbox.add_css_class ("med-font");
                note_textbox.remove_css_class ("big-font");
                break;
                case "'large'":
                note_textbox.remove_css_class ("sml-font");
                note_textbox.remove_css_class ("med-font");
                note_textbox.add_css_class ("big-font");
                break;
            }
            settings.notify["font-size"].connect (() => {
                switch (settings.font_size) {
                    case "'small'":
                    note_textbox.add_css_class ("sml-font");
                    note_textbox.remove_css_class ("med-font");
                    note_textbox.remove_css_class ("big-font");
                    break;
                    default:
                    case "'medium'":
                    note_textbox.remove_css_class ("sml-font");
                    note_textbox.add_css_class ("med-font");
                    note_textbox.remove_css_class ("big-font");
                    break;
                    case "'large'":
                    note_textbox.remove_css_class ("sml-font");
                    note_textbox.remove_css_class ("med-font");
                    note_textbox.add_css_class ("big-font");
                    break;
                }
            });

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_note.color));
            vm.update_note_color (_note, _note.color);

            note_textbox.grab_focus ();

            // ListView Back Button
            bb_binding = ((Adw.Leaflet)MiscUtils.find_ancestor_of_type<Adw.Leaflet>(this)).bind_property ("folded", back_button, "visible", SYNC_CREATE);
            back_button.clicked.connect (() => {
                ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).leaf.set_visible_child (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).sgrid);
            });

            // GridView Back Button
            if (((Adw.Leaflet)MiscUtils.find_ancestor_of_type<Adw.Leaflet>(this)).folded) {
                back2_button.visible = false;
            } else {
                back2_button.visible = ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).sgrid.get_visible_child_name () == "notegrid" != false ? true : false;
            }
            back2_button.clicked.connect (() => {
                ((Adw.Leaflet)MiscUtils.find_ancestor_of_type<Adw.Leaflet>(this)).set_visible_child (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).sgrid);
                ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).sgrid.set_visible (true);
                ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).grid.set_visible (false);
            });

            if (_note != null) {
                _note.notify.connect (on_text_updated);
                if (image.file != "") {
                    note_header.add_css_class ("scrim");
                    note_header.remove_css_class ("content-header");
                } else {
                    note_header.remove_css_class ("scrim");
                    note_header.add_css_class ("content-header");
                }
            }
        }
    }

    public NoteContentView (NoteViewModel? vm) {
        Object (
            vm: vm
        );
    }

    construct {
        fmt_syntax_start ();
        main_box.get_style_context().add_provider(provider, 1);
    }

    public signal void note_update_requested (Note note);
    public signal void note_removal_requested (Note note);

    void on_text_updated () {
        note_update_requested (note);
        fmt_syntax_start ();
    }

    public async void export_note (NoteViewModel vm, Note note) throws Error {
        debug ("Export button pressed.");
        string tasks = "";
        var file = yield MiscUtils.display_save_dialog (((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)));

        tasks += "% " + note.title + "\n% " + note.subtitle + "\n% Notebook: " + note.notebook + "\n\n" + note.text;

        GLib.FileUtils.set_contents (file.get_path(), tasks);
    }

    [GtkCallback]
    public async void action_picture () {
        // implement picture
        debug ("Open button pressed.");
        var file = yield MiscUtils.display_open_dialog (((MainWindow) MiscUtils.find_ancestor_of_type<MainWindow> (this)));

        note.picture = file.get_path ();
        image.file = file.get_path ();
        image_button.visible = false;
        image_remove_button.visible = true;
        note_header.add_css_class ("scrim");
        note_header.remove_css_class ("content-header");
        note_update_requested (note);
    }

    [GtkCallback]
    public void action_picture_remove () {
        note.picture = "";
        image.clear_image ();
        image_button.visible = true;
        image_remove_button.visible = false;
        note_header.remove_css_class ("scrim");
        note_header.add_css_class ("content-header");
        note_update_requested (note);
    }

    public void fmt_syntax_start () {
        if (update_idle_source > 0) {
            GLib.Source.remove (update_idle_source);
        }

        update_idle_source = GLib.Idle.add (() => {
            var text_buffer = note_textbox.get_buffer();
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

    private void erase_utf8 (StringBuilder builder, ssize_t start, ssize_t len) {
        // erase a range in a string with respect to special offsets
        // because of utf8
        int real_start = builder.str.index_of_nth_char(start);
        builder.erase(real_start, len);
    }

    [GtkCallback]
    public void action_normal () {
        var textfield = note_textbox;
        if (textfield != null) {
            Gtk.TextIter sel_start, sel_end;
            int offset = 0, fmt_start, fmt_end;
            int move_forward = 0, move_backward = 0;
            string wrap = "";

            var text_buffer = textfield.get_buffer ();

            //only record a single user action for the entire function
            text_buffer.begin_user_action();
            //ensure the selection is correctly extended
            extend_selection_to_format_block (textfield);

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

    [GtkCallback]
    public void action_bold () {
        var textfield = note_textbox;
        if (textfield != null) {
            text_wrap(textfield, "**", _("bold text"));
        }
    }

    [GtkCallback]
    public void action_italic () {
        var textfield = note_textbox;
        if (textfield != null) {
            text_wrap(textfield, "*", _("italic text"));
        }
    }

    [GtkCallback]
    public void action_ul () {
        var textfield = note_textbox;
        if (textfield != null) {
            text_wrap(textfield, "_", _("underline text"));
        }
    }

    [GtkCallback]
    public void action_s () {
        var textfield = note_textbox;
        if (textfield != null) {
            text_wrap(textfield, "~", _("strikethrough text"));
        }
    }

    [GtkCallback]
    public void action_item () {
        var textfield = note_textbox;
        if (textfield != null) {
            insert_item(textfield, _("Item"));
        }
    }

    public void extend_selection_to_format_block(Gtk.TextView text_view, Format? format = null) {
        Gtk.TextIter sel_start, sel_end;
        var text_buffer = text_view.get_buffer();
        text_buffer.get_selection_bounds (out sel_start, out sel_end);
        int start_rel, end_rel;
        string wrap;

        foreach (FormatBlock fmt in fmt_syntax_blocks(text_buffer)) {
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

    public void text_wrap(Gtk.TextView text_view, string wrap, string helptext) {
        extend_selection_to_format_block(text_view, string_to_format(wrap));

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
        Gtk.TextIter start, end, starts, ends, cursor_iter;
        text_buffer.get_selection_bounds(out start, out end);

        if (text_buffer.get_has_selection()) {
            text = text_buffer.get_text(start, end, false);
            if (text.has_prefix("- ")){
                var lines = text.strip ().split("\n");
                string list_line = "";

                foreach (var line in lines) {
                    if (line == lines[0]) {
                        list_line += line.replace("- ", "");
                    } else {
                        list_line += "\n" + line.replace("- ", "");
                    }
                }
                text_buffer.insert(ref start, list_line, -1);

                text_buffer.get_selection_bounds(out starts, out ends);
                text_buffer.delete(ref starts, ref ends);

                select_text(text_view, 0, list_line.length);
            } else {
                var lines = text.strip ().split("\n");
                string list_line = "";

                foreach (var line in lines) {
                    if (line == lines[0]) {
                        list_line += "- " + line;
                    } else {
                        list_line += "\n" + "- " + line;
                    }
                }
                text_buffer.insert(ref start, list_line, -1);

                text_buffer.get_selection_bounds(out starts, out ends);
                text_buffer.delete(ref starts, ref ends);

                select_text(text_view, 0, list_line.length);
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

    public FormatBlock[] fmt_syntax_blocks(Gtk.TextBuffer buffer) {
        Gtk.TextIter start, end;
        int match_start_offset, match_end_offset;
        FormatBlock[] format_blocks = {};

        GLib.MatchInfo match;

        buffer.get_bounds(out start, out end);
        string measure_text, buf = buffer.get_text (start, end, true);

        try {
            var regex = new Regex("""(?s)(?<wrap>\*{2}|[*_~]).*\g{wrap}""");

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

    public string get_selected_text (Gtk.TextBuffer buffer) {
        Gtk.TextIter A;
        Gtk.TextIter B;
        if (buffer.get_selection_bounds (out A, out B)) {
            return buffer.get_text(A, B, true);
        }

        return "";
    }
}
