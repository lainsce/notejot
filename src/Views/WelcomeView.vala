namespace Notejot {
    public class Views.WelcomeView : Gtk.Grid {
        public MainWindow win;

        public WelcomeView (MainWindow win) {
            this.win = win;

            var normal_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DND);
            var normal_label = new Gtk.Label (_("Start by adding some notes…"));
            var normal_label_context = normal_label.get_style_context ();
            normal_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            normal_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            this.column_spacing = 12;
            this.margin = 24;
            this.expand = true;
            this.halign = this.valign = Gtk.Align.CENTER;
            this.add (normal_icon);
            this.add (normal_label);
            this.show_all ();
        }
    }
}