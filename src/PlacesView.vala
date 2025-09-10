// PlacesView.vala
namespace Notejot {
    public class PlacesView : Gtk.Box {
        private Shumate.Map map_widget;
        private Shumate.MarkerLayer marker_layer;
        private DataManager data_manager;
        private Gtk.Label total_locations_label;

        public PlacesView(DataManager manager) {
            Object(
                   orientation : Gtk.Orientation.VERTICAL,
                   spacing: 0
            );
            add_css_class ("places-view");
            data_manager = manager;

            var appbar = new He.AppBar();
            appbar.add_css_class ("places-view-appbar");
            appbar.show_left_title_buttons = false;
            var main_header_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            main_header_box.add_css_class ("places-view-header");
            main_header_box.set_valign(Gtk.Align.START);

            var header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            main_header_box.append(header_box);
            var title_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
                hexpand = true
            };
            header_box.append(title_box);

            var header = new Gtk.Label(_("Places")) {
                halign = Gtk.Align.START
            };
            header.add_css_class ("header");
            title_box.append(header);

            total_locations_label = new Gtk.Label("0 Locations") {
                halign = Gtk.Align.START
            };
            total_locations_label.add_css_class ("date-label");
            title_box.append(total_locations_label);

            // Map setup
            map_widget = new Shumate.Map.simple();
            map_widget.set_vexpand(true);
            marker_layer = new Shumate.MarkerLayer(map_widget.get_viewport());
            map_widget.add_layer(marker_layer);
            map_widget.get_viewport().zoom_level = 2;

            map_widget.realize.connect(() => {
                map_widget.queue_draw();
            });

            var overlay = new Gtk.Overlay();
            overlay.add_overlay (main_header_box);
            overlay.set_child (map_widget);
            append(appbar);
            append(overlay);

            refresh_pins();
        }

        public void refresh_pins() {
            marker_layer.remove_all();
            int location_count = 0;

            foreach (var entry in data_manager.get_entries()) {
                if (!entry.is_deleted && entry.latitude != null && entry.longitude != null) {
                    location_count++;
                    var marker = new Shumate.Marker();
                    var marker_image = new Gtk.Image.from_icon_name("marker-pin") { pixel_size = 24 };
                    marker.set_child(marker_image);
                    marker.set_location(entry.latitude, entry.longitude);
                    marker_layer.add_marker(marker);
                }
            }
            total_locations_label.set_label(@"$(location_count) Locations");
        }
    }
}
