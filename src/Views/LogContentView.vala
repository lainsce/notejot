[GtkTemplate (ui = "/io/github/lainsce/Notejot/logcontentview.ui")]
public class Notejot.LogContentView : View {
    Log? _note;
    public LogViewModel? vm {get; set;}

    [GtkChild]
    public unowned Gtk.Stack stack;

    [GtkChild]
    public unowned Gtk.Box note_view;
    [GtkChild]
    public unowned Adw.StatusPage empty_view;
    [GtkChild]
    public unowned Gtk.MenuButton settingmenu;

    [GtkChild]
    unowned Gtk.Box note_header;
    [GtkChild]
    unowned Gtk.ActionBar note_footer;

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

    public Widgets.SettingMenu sm;

    Binding? title_binding;
    Binding? subtitle_binding;
    Binding? notebook_binding;
    Binding? text_binding;
    Binding? color_binding;

    public Log? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            _note = value;

            title_binding?.unbind ();
            subtitle_binding?.unbind ();
            notebook_binding?.unbind ();
            text_binding?.unbind ();
            color_binding?.unbind ();

            _note = value;

            format_revealer.reveal_child = _note != null ? true : false;
            settingmenu.visible = _note != null ? true : false;
            stack.visible_child = _note != null ? (Gtk.Widget) note_view : empty_view;

            sm = new Widgets.SettingMenu(vm, _note.color);
            sm.controller = _note;

            var sbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/note_menu.ui");
            var smenu = (Menu)sbuilder.get_object ("smenu");

            settingmenu.menu_model = smenu;

            var popover = settingmenu.get_popover ();
            popover.add_child (sbuilder, sm.nmp, "theme");

            note_title.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY,"document-edit-symbolic");
            note_title.set_icon_activatable (Gtk.EntryIconPosition.SECONDARY, true);
            note_title.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Set Note Title"));

            title_binding = _note?.bind_property (
              "title", note_title, "text", SYNC_CREATE|BIDIRECTIONAL);
            subtitle_binding = _note?.bind_property (
              "subtitle", note_subtitle, "label", SYNC_CREATE|BIDIRECTIONAL);
            notebook_binding = _note?.bind_property (
              "notebook", notebook_subtitle, "label", SYNC_CREATE|BIDIRECTIONAL);
            text_binding = _note?.bind_property (
              "text", note_text, "text", SYNC_CREATE|BIDIRECTIONAL);
            color_binding = _note?.bind_property (
              "color", sm, "color", SYNC_CREATE|BIDIRECTIONAL);

            note_title.activate.connect (() => {
                _note.title = note_title.get_text ();
            });
            note_title.icon_press.connect (() => {
                _note.title = note_title.get_text ();
            });

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

            note_header.add_css_class ("notejot-header-%s".printf(_note.id));
            note_textbox.add_css_class ("notejot-view-%s".printf(_note.id));
            note_footer.add_css_class ("notejot-footer-%s".printf(_note.id));

            vm.update_note_color (_note, _note.color);

        }
    }

    public LogContentView (LogViewModel? vm) {
        Object (vm: vm);
    }

    public signal void note_update_requested (Log note);
    public signal void note_removal_requested (Log note);

    [GtkCallback]
    void on_text_updated () {
        note_update_requested (note);
    }

    [GtkCallback]
    void on_delete_button_clicked () {
        note_removal_requested (note);
    }
}
