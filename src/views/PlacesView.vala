// PlacesView.vala
namespace Notejot {
    public class PlacesView : Gtk.Box {
        private Shumate.SimpleMap map_widget;
        private Shumate.Map base_map;
        private Shumate.MarkerLayer marker_layer;
        private Shumate.MapSourceRegistry registry;
        private DataManager data_manager;
        private Gtk.Label total_locations_label;
        private Gtk.Box location_notes_panel;
        private Gtk.Box location_notes_content_box;

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

            // Bottom-right panel for location notes
            location_notes_panel = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.END
            };
            location_notes_panel.set_margin_end (18);
            location_notes_panel.set_margin_bottom (18);
            location_notes_panel.set_size_request (320, -1);
            location_notes_panel.add_css_class ("location-notes-panel");
            location_notes_panel.set_visible (false);

            var panel_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var panel_title = new Gtk.Label (_("This Location's Notes")) { halign = Gtk.Align.START };
            panel_title.add_css_class ("title-4");
            panel_header.append (panel_title);
            panel_header.append (new Gtk.Label ("") { hexpand = true });
            var close_button = new He.Button ("window-close-symbolic", "");
            close_button.is_disclosure = true;
            close_button.clicked.connect (() => {
                location_notes_panel.set_visible (false);
            });
            panel_header.append (close_button);
            location_notes_panel.append (panel_header);

            var scroller = new Gtk.ScrolledWindow ();
            scroller.set_min_content_height (220);
            scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            location_notes_content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            location_notes_content_box.set_margin_top (6);
            location_notes_content_box.set_margin_end (16);
            scroller.set_child (location_notes_content_box);
            location_notes_panel.append (scroller);

            overlay.add_overlay (location_notes_panel);

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

                // Open the location notes panel when this marker is clicked
                var lat_rounded = Math.round (entry.latitude * 10000) / 10000;
                var lon_rounded = Math.round (entry.longitude * 10000) / 10000;
                var click = new Gtk.GestureClick ();
                click.pressed.connect ((n_press, x, y) => {
                    show_location_notes (lat_rounded, lon_rounded);
                });
                marker.add_controller (click);

                marker_layer.add_marker (marker);
            }

            total_locations_label.set_label (@"$(unique_locations.length()) Locations");
        }

        private void show_location_notes (double lat, double lon) {
            if (location_notes_panel == null)
                return;

            // Clear previous items
            Gtk.Widget? child = location_notes_content_box.get_first_child ();
            while (child != null) {
                location_notes_content_box.remove (child);
                child = location_notes_content_box.get_first_child ();
            }

            var lat_r = Math.round (lat * 10000) / 10000;
            var lon_r = Math.round (lon * 10000) / 10000;

            int count = 0;
            foreach (var e in data_manager.entries) {
                if (!e.is_deleted && e.latitude != null && e.longitude != null) {
                    var elat_r = Math.round (e.latitude * 10000) / 10000;
                    var elon_r = Math.round (e.longitude * 10000) / 10000;
                    if (elat_r == lat_r && elon_r == lon_r) {
                        var row = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                        row.add_css_class ("note-card");

                        var title = new Gtk.Label (e.title) {
                            halign = Gtk.Align.START,
                            wrap = true
                        };
                        row.append (title);

                        // Build info line: preview • time • tags
                        string preview = "";
                        foreach (var line in e.content.split ("\n")) {
                            var trimmed = line.strip ();
                            if (trimmed.length > 0 && !trimmed.has_prefix ("[Color:")) {
                                preview = trimmed;
                                break;
                            }
                        }

                        // Concise time
                        int64 now = new GLib.DateTime.now_utc ().to_unix ();
                        int64 diff = now - e.creation_timestamp;
                        if (diff < 0)diff = 0;
                        string time_str = "";
                        if (diff < 60) {
                            time_str = @"$(diff)s ago";
                        } else if (diff < 3600) {
                            var m = diff / 60;
                            time_str = @"$(m)m ago";
                        } else if (diff < 86400) {
                            var h = diff / 3600;
                            time_str = @"$(h)h ago";
                        } else if (diff < 604800) {
                            var d = diff / 86400;
                            time_str = @"$(d)d ago";
                        } else if (diff < 2592000) {
                            var w = diff / 604800;
                            time_str = @"$(w)w ago";
                        } else if (diff < 31536000) {
                            var mo = diff / 2592000;
                            time_str = @"$(mo)mo ago";
                        } else {
                            var y = diff / 31536000;
                            time_str = @"$(y)y ago";
                        }

                        // Tags (from tag UUIDs)
                        string tags_str = "";
                        bool first = true;
                        foreach (var uuid in e.tag_uuids) {
                            foreach (var t in data_manager.tags) {
                                if (t != null && t.uuid == uuid) {
                                    if (!first) {
                                        tags_str += ", ";
                                    }
                                    tags_str += t.name;
                                    first = false;
                                    break;
                                }
                            }
                        }

                        // Truncate content preview to 40 chars
                        if (preview != "" && preview.length > 40) {
                            preview = preview.substring (0, 40) + "…";
                        }
                        var preview_label = new Gtk.Label (preview) {
                            halign = Gtk.Align.START,
                            wrap = false
                        };
                        preview_label.add_css_class ("dim-label");
                        row.append (preview_label);

                        // Tags chips + Timestamp (timestamp at end)
                        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

                        var chips = new Gtk.FlowBox ();
                        chips.set_selection_mode (Gtk.SelectionMode.NONE);
                        chips.set_max_children_per_line (10);
                        chips.set_min_children_per_line (1);
                        chips.set_row_spacing (4);
                        chips.set_column_spacing (4);

                        foreach (var uuid in e.tag_uuids) {
                            foreach (var t in data_manager.tags) {
                                if (t != null && t.uuid == uuid) {


                                    var chip = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
                                    chip.add_css_class ("tag-chip");
                                    chip.set_margin_top (2);
                                    chip.set_margin_bottom (2);

                                    // Use predefined tag chip color classes instead of inline CSS
                                    var color_class = "default";
                                    switch (t.color.down ()) {
                                    case "#e57373" : case "#ef5350": color_class = "red"; break;
                                    case "#ffb74d": case "#ffa726": color_class = "orange"; break;
                                    case "#ffd54f": case "#ffe082": color_class = "yellow"; break;
                                    case "#81c784": case "#66bb6a": color_class = "green"; break;
                                    case "#4db6ac": case "#26a69a": color_class = "mint"; break;
                                    case "#4dd0e1": case "#26c6da": color_class = "teal"; break;
                                    case "#32ade6": case "#29b6f6": color_class = "cyan"; break;
                                    case "#64b5f6": case "#42a5f5": color_class = "blue"; break;
                                    case "#7986cb": case "#5c6bc0": color_class = "indigo"; break;
                                    case "#ba68c8": case "#ab47bc": color_class = "purple"; break;
                                    case "#f06292": case "#ec407a": color_class = "pink"; break;
                                    case "#bcaaa4": case "#a1887f": color_class = "brown"; break;
                                    default: break;
                                    }
                                    if (color_class != "default") {
                                        chip.add_css_class ("tag-chip-" + color_class);
                                    }

                                    var name_lbl = new Gtk.Label (t.name) {
                                        halign = Gtk.Align.START
                                    };
                                    chip.append (name_lbl);

                                    chips.insert (chip, -1);
                                    break;
                                }
                            }
                        }

                        bottom_box.append (chips);
                        bottom_box.append (new Gtk.Label ("") { hexpand = true });

                        var time_lbl = new Gtk.Label (time_str) {
                            halign = Gtk.Align.END,
                            wrap = false
                        };
                        time_lbl.add_css_class ("dim-label");
                        bottom_box.append (time_lbl);

                        row.append (bottom_box);

                        location_notes_content_box.append (row);
                        count++;
                    }
                }
            }

            location_notes_panel.set_visible (count > 0);
        }
    }
}
