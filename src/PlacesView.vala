// PlacesView.vala
namespace Notejot {
    public class PlacesView : Gtk.Box {
        private Shumate.SimpleMap map_widget;
        private Shumate.Map base_map;
        private Shumate.MarkerLayer marker_layer;
        private Shumate.MapSourceRegistry registry;
        private DataManager data_manager;
        private Gtk.Label total_locations_label;

        public Shumate.MapSource map_source {
            get {
                return map_widget.map_source;
            }

            set {
                map_widget.map_source = value;
            }
        }

        public PlacesView (DataManager manager) {
            Object (
                    orientation: Gtk.Orientation.VERTICAL,
                    spacing: 0
            );
            add_css_class ("places-view");
            data_manager = manager;

            var appbar = new He.AppBar ();
            appbar.add_css_class ("places-view-appbar");
            appbar.show_left_title_buttons = false;
            var main_header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            main_header_box.add_css_class ("places-view-header");
            main_header_box.set_valign (Gtk.Align.START);

            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            main_header_box.append (header_box);
            var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                hexpand = true
            };
            header_box.append (title_box);

            var header = new Gtk.Label (_("Places")) {
                halign = Gtk.Align.START
            };
            header.add_css_class ("header");
            title_box.append (header);

            total_locations_label = new Gtk.Label ("0 Locations") {
                halign = Gtk.Align.START
            };
            total_locations_label.add_css_class ("date-label");
            title_box.append (total_locations_label);

            // Map setup
            map_widget = new Shumate.SimpleMap ();
            map_widget.set_vexpand (true);
            map_widget.set_hexpand (true);
            map_widget.show_zoom_buttons = false;
            map_widget.license.visible = false;
            map_widget.scale.visible = false;
            base_map = map_widget.map;

            setup_map_source_action ();

            map_widget.realize.connect (() => {
                map_widget.queue_draw ();
            });

            marker_layer = new Shumate.MarkerLayer (map_widget.get_viewport ());
            map_widget.add_overlay_layer (marker_layer);

            var overlay = new Gtk.Overlay ();
            overlay.add_overlay (main_header_box);
            overlay.set_child (map_widget);
            append (appbar);
            append (overlay);

            refresh_pins ();
        }

        private void setup_map_source_action () {
            registry = new Shumate.MapSourceRegistry.with_defaults ();

            try {
                load_vector_tiles ();
            } catch (Error e) {
                critical ("Failed to create vector map style: %s", e.message);
            }

            var map_source_action = NotejotApp.settings.create_action ("map-source");
            var window = this.get_ancestor (typeof (Gtk.ApplicationWindow)) as Gtk.ApplicationWindow;
            if (window != null) {
                window.add_action (map_source_action);
            }

            NotejotApp.settings.bind_with_mapping (
                                                   "map-source", map_widget, "map-source", GET,
                                                   (SettingsBindGetMappingShared) map_source_get_mapping_cb,
                                                   (SettingsBindSetMappingShared) null,
                                                   registry, null
            );
        }

        private void load_vector_tiles () throws Error requires (Shumate.VectorRenderer.is_supported ()) {
            var style_json = new Notejot.MapStyle ("notejot-light").to_string ();
            critical (style_json);

            var renderer = new Shumate.VectorRenderer ("notejot-light", style_json) {
                max_zoom_level = 14,
                min_zoom_level = 1
            };
            registry.add (renderer);
        }

        public static bool map_source_get_mapping_cb (Value value, Variant variant, void* user_data) {
            unowned var registry = user_data as Shumate.MapSourceRegistry;
            if (registry == null) {
                warning ("map_source_get_mapping_cb: Invalid user_data");
                return false;
            }

            string map_source;
            var val = (string) variant;
            switch (val) {
            case "explore":
                map_source = "notejot-light";
                break;
            default:
                warning ("map_source_get_mapping_cb: Invalid map_source: %s", val);
                return false;
            }

            value.set_object (registry.get_by_id (map_source));

            return true;
        }

        public void refresh_pins () {
            marker_layer.remove_all ();

            // Get unique locations only
            var unique_locations = data_manager.get_unique_locations ();

            foreach (var entry in unique_locations) {
                var marker = new Shumate.Marker ();
                var marker_image = new Gtk.Image.from_icon_name ("marker-pin") { pixel_size = 24 };
                marker.set_child (marker_image);
                marker.set_location (entry.latitude, entry.longitude);
                marker_layer.add_marker (marker);
            }

            total_locations_label.set_label (@"$(unique_locations.length()) Locations");
        }
    }
}
