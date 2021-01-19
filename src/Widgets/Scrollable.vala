namespace Notejot {
    public class Widgets.Scrollable : Gtk.Bin, Gtk.Scrollable {
        public Gtk.Widget header { get; set; }
        public int header_height { get; private set; }

        public Gtk.Adjustment vadjustment { get; set; }
        public Gtk.Adjustment hadjustment { get; set; }
        public Gtk.ScrollablePolicy vscroll_policy { get; set; }
        public Gtk.ScrollablePolicy hscroll_policy { get; set; }

        private Gtk.Scrollable scrollable;

        construct {
            /* TODO: Support other scrollables, create this widget when adding a child dynamically */
            scrollable = new Gtk.Viewport (null, null);

            bind_property ("vadjustment", scrollable, "vadjustment", BindingFlags.SYNC_CREATE);
            bind_property ("hadjustment", scrollable, "hadjustment", BindingFlags.SYNC_CREATE);
            bind_property ("vscroll-policy", scrollable, "vscroll-policy", BindingFlags.SYNC_CREATE);
            bind_property ("hscroll-policy", scrollable, "hscroll-policy", BindingFlags.SYNC_CREATE);

            var widget = scrollable as Gtk.Widget;
            widget.show ();
            add (widget);
        }

        protected bool get_border (out Gtk.Border border) {
            if (scrollable != null)
                scrollable.get_border (out border);
            else
                border = {};

            header_height = header.get_allocated_height ();
            border.top += (int16) header_height;

            return true;
        }

        protected override void add (Gtk.Widget widget) {
            if (get_child () == null) {
                base.add (widget);
                return;
            }

            if (scrollable is Gtk.Container) {
                var container = scrollable as Gtk.Container;
                container.add (widget);
            }
        }

        protected override void remove (Gtk.Widget widget) {
            if (widget == scrollable as Gtk.Widget) {
                base.remove (widget);
                return;
            }
            
            if (scrollable is Gtk.Container) {
                var child = scrollable as Gtk.Container;
                child.remove (widget);
            }
        }

        protected override void forall_internal (bool include_internals, Gtk.Callback callback) {
            if (scrollable == null)
                return;

            if (include_internals)
                callback (scrollable as Gtk.Widget);
            else if (scrollable is Gtk.Container) {
                var child = scrollable as Gtk.Container;
                child.foreach (callback);
            }
        }
    }
}