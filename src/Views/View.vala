public abstract class Notejot.View : Gtk.Widget, Gtk.Buildable {
  Adw.Bin? child_bin = new Adw.Bin () { vexpand = true };

  public Gtk.Widget? child {
    get { return child_bin.child; }
    set { child_bin.child = value; }
  }

  construct {
    layout_manager = new Gtk.BoxLayout (VERTICAL);

    child_bin?.set_parent (this);
  }

  protected override void dispose () {
    child_bin?.unparent ();
    child_bin = null;

    base.dispose ();
  }

  void add_child (Gtk.Builder builder, Object child, string? type) {
    if (child is Gtk.Widget) {
      this.child = (Gtk.Widget) child;
      return;
    }

    base.add_child (builder, child, type);
  }
}
