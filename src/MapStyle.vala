// https://openmaptiles.org/docs/style/mapbox-gl-style-spec/
// https://openmaptiles.org/schema/
public class Notejot.MapStyle : Notejot.JsonObject {
    public int version { get; private set; }
    public string name { get; construct set; }
    public Sources sources { get; private set; }
    public Gee.ArrayList<Layer> layers { get; private set; }

    // Colors from style.css
    private const string RED = "#e57373";
    private const string ORANGE = "#ffb74d";
    private const string YELLOW = "#ffd54f";
    private const string GREEN = "#81c784";
    private const string MINT = "#4db6ac";
    private const string TEAL = "#4dd0e1";
    private const string CYAN = "#32ade6";
    private const string BLUE = "#64b5f6";
    private const string INDIGO = "#7986cb";
    private const string PURPLE = "#ba68c8";
    private const string PINK = "#f06292";
    private const string BROWN = "#bcaaa4";
    private const string TEXT_PRIMARY = "#1d1d1f";
    private const string TEXT_SECONDARY = "#8a8a8e";
    private const string BORDER_COLOR = "#e8e3e0";
    private const string APP_BG = "#f9f5f4";

    public MapStyle (string name) {
        Object (name: name);
    }

    construct {
        version = 8;
        sources = new Sources ();
        layers = new Gee.ArrayList<Layer> (null);

        // Background layer
        var background = new Layer () {
            id = "background",
            kind = "background",
            paint = new Layer.Paint () {
                background_color = GREEN
            }
        };
        layers.add (background);

        // Land layer
        var land = new Layer () {
            id = "land",
            kind = "fill",
            source = "vector-tiles",
            source_layer = "landcover",
            paint = new Layer.Paint () {
                fill_color = APP_BG,
                fill_opacity = 0.3
            }
        };
        layers.add (land);

        // Water layer
        var water_filter = new Notejot.Expression ("all");
        water_filter.append_string_string ("!=", "brunnel", "tunnel");

        var water = new Layer () {
            id = "water",
            kind = "fill",
            source = "vector-tiles",
            source_layer = "water",
            filter = water_filter,
            paint = new Layer.Paint () {
                fill_color = BLUE
            }
        };
        layers.add (water);

        // Parks and natural areas
        var park_filter = new Notejot.Expression ("all");
        park_filter.append_string_string ("==", "class", "park");

        var park = new Layer () {
            id = "park",
            kind = "fill",
            source = "vector-tiles",
            source_layer = "landuse",
            filter = park_filter,
            paint = new Layer.Paint () {
                fill_color = GREEN,
                fill_opacity = 0.2
            }
        };
        layers.add (park);

        // Country boundaries
        var admin_filter = new Notejot.Expression ("all");
        admin_filter.append_string_int ("<=", "admin_level", 2);

        var admin_line = new Layer () {
            id = "admin_country",
            kind = "line",
            source = "vector-tiles",
            source_layer = "boundary",
            filter = admin_filter,
            paint = new Layer.Paint () {
                line_color = BORDER_COLOR,
                line_opacity = 0.8
            },
            layout = new Layer.Layout () {
                line_cap = "round",
                line_join = "round"
            }
        };
        var admin_dash = new Json.Array ();
        admin_dash.add_double_element (2);
        admin_dash.add_double_element (2);
        admin_line.paint.line_dasharray = admin_dash;
        layers.add (admin_line);

        // State boundaries
        var state_filter = new Notejot.Expression ("all");
        state_filter.append_string_int ("==", "admin_level", 4);

        var state_line = new Layer () {
            id = "admin_state",
            kind = "line",
            source = "vector-tiles",
            source_layer = "boundary",
            filter = state_filter,
            paint = new Layer.Paint () {
                line_color = BORDER_COLOR,
                line_opacity = 0.4
            },
            layout = new Layer.Layout () {
                line_cap = "round",
                line_join = "round"
            }
        };
        var state_dash = new Json.Array ();
        state_dash.add_double_element (1);
        state_dash.add_double_element (1);
        state_line.paint.line_dasharray = state_dash;
        layers.add (state_line);

        // Major roads
        var major_road_filter = new Notejot.Expression ("all");
        major_road_filter.append_string_string ("in", "class", "motorway");

        var major_road_width = new InterpolateExpression () {
            base_val = 1.2
        };
        var major_road_stops = new Json.Array ();
        major_road_stops.add_int_element (5);
        major_road_stops.add_double_element (0.5);
        var major_road_stops2 = new Json.Array ();
        major_road_stops2.add_int_element (9);
        major_road_stops2.add_double_element (2);
        var major_road_stops3 = new Json.Array ();
        major_road_stops3.add_int_element (14);
        major_road_stops3.add_double_element (8);
        major_road_width.stops.add (major_road_stops);
        major_road_width.stops.add (major_road_stops2);
        major_road_width.stops.add (major_road_stops3);

        var major_road = new Layer () {
            id = "road_major",
            kind = "line",
            source = "vector-tiles",
            source_layer = "transportation",
            filter = major_road_filter,
            paint = new Layer.Paint () {
                line_color = ORANGE,
                line_opacity = 0.8,
                line_width = major_road_width
            },
            layout = new Layer.Layout () {
                line_cap = "round",
                line_join = "round"
            }
        };
        layers.add (major_road);

        // Minor roads
        var minor_road_filter = new Notejot.Expression ("all");
        minor_road_filter.append_string_string ("in", "class", "primary");

        var minor_road_width = new InterpolateExpression () {
            base_val = 1.2
        };
        var minor_road_stops = new Json.Array ();
        minor_road_stops.add_int_element (8);
        minor_road_stops.add_double_element (0.5);
        var minor_road_stops2 = new Json.Array ();
        minor_road_stops2.add_int_element (12);
        minor_road_stops2.add_double_element (2);
        var minor_road_stops3 = new Json.Array ();
        minor_road_stops3.add_int_element (16);
        minor_road_stops3.add_double_element (4);
        minor_road_width.stops.add (minor_road_stops);
        minor_road_width.stops.add (minor_road_stops2);
        minor_road_width.stops.add (minor_road_stops3);

        var minor_road = new Layer () {
            id = "road_minor",
            kind = "line",
            source = "vector-tiles",
            source_layer = "transportation",
            filter = minor_road_filter,
            paint = new Layer.Paint () {
                line_color = YELLOW,
                line_opacity = 0.6,
                line_width = minor_road_width
            },
            layout = new Layer.Layout () {
                line_cap = "round",
                line_join = "round"
            }
        };
        layers.add (minor_road);

        // Buildings
        var building_filter = new Notejot.Expression ("all");
        building_filter.append_string_int (">=", "zoom", 14);

        var building = new Layer () {
            id = "building",
            kind = "fill",
            source = "vector-tiles",
            source_layer = "building",
            minzoom = 14,
            filter = building_filter,
            paint = new Layer.Paint () {
                fill_color = BORDER_COLOR,
                fill_opacity = 0.7,
                fill_outline_color = TEXT_SECONDARY
            }
        };
        layers.add (building);

        // Place labels - Countries
        var place_country_filter = new Notejot.Expression ("all");
        place_country_filter.append_string_string ("==", "class", "country");

        var country_text_size = new InterpolateExpression () {
            base_val = 1
        };
        var country_stops = new Json.Array ();
        country_stops.add_int_element (2);
        country_stops.add_double_element (10);
        var country_stops2 = new Json.Array ();
        country_stops2.add_int_element (6);
        country_stops2.add_double_element (14);
        country_text_size.stops.add (country_stops);
        country_text_size.stops.add (country_stops2);

        var place_country = new Layer () {
            id = "place_country",
            kind = "symbol",
            source = "vector-tiles",
            source_layer = "place",
            minzoom = 2,
            maxzoom = 6,
            filter = place_country_filter,
            layout = new Layer.Layout () {
                text_anchor = "center",
                text_field = "{name_en}",
                text_font = { "Geist Bold" },
                text_max_width = 10,
                text_size = country_text_size
            },
            paint = new Layer.Paint () {
                text_color = TEXT_PRIMARY
            }
        };
        layers.add (place_country);

        // Place labels - States
        var place_state_filter = new Notejot.Expression ("all");
        place_state_filter.append_string_string ("==", "class", "state");

        var state_text_size = new InterpolateExpression () {
            base_val = 1
        };
        var state_stops = new Json.Array ();
        state_stops.add_int_element (4);
        state_stops.add_double_element (8);
        var state_stops2 = new Json.Array ();
        state_stops2.add_int_element (8);
        state_stops2.add_double_element (12);
        state_text_size.stops.add (state_stops);
        state_text_size.stops.add (state_stops2);

        var place_state = new Layer () {
            id = "place_state",
            kind = "symbol",
            source = "vector-tiles",
            source_layer = "place",
            minzoom = 4,
            maxzoom = 10,
            filter = place_state_filter,
            layout = new Layer.Layout () {
                text_anchor = "center",
                text_field = "{name_en}",
                text_font = { "Geist Medium" },
                text_max_width = 8,
                text_size = state_text_size
            },
            paint = new Layer.Paint () {
                text_color = TEXT_SECONDARY
            }
        };
        layers.add (place_state);

        // Place labels - Cities
        var place_city_filter = new Notejot.Expression ("all");
        place_city_filter.append_string_string ("==", "class", "city");

        var city_text_size = new InterpolateExpression () {
            base_val = 1
        };
        var city_stops = new Json.Array ();
        city_stops.add_int_element (6);
        city_stops.add_double_element (10);
        var city_stops2 = new Json.Array ();
        city_stops2.add_int_element (12);
        city_stops2.add_double_element (16);
        city_text_size.stops.add (city_stops);
        city_text_size.stops.add (city_stops2);

        var place_city = new Layer () {
            id = "place_city",
            kind = "symbol",
            source = "vector-tiles",
            source_layer = "place",
            minzoom = 6,
            maxzoom = 14,
            filter = place_city_filter,
            layout = new Layer.Layout () {
                text_anchor = "bottom",
                text_field = "{name_en}",
                text_font = { "Geist Medium" },
                text_max_width = 8,
                text_size = city_text_size,
                icon_allow_overlap = true,
                icon_optional = false
            },
            paint = new Layer.Paint () {
                text_color = TEXT_PRIMARY
            }
        };
        var city_offset = new Json.Array ();
        city_offset.add_double_element (0);
        city_offset.add_double_element (0);
        place_city.layout.text_offset = city_offset;
        layers.add (place_city);

        // Place labels - Towns
        var place_town_filter = new Notejot.Expression ("all");
        place_town_filter.append_string_string ("==", "class", "town");

        var town_text_size = new InterpolateExpression () {
            base_val = 1
        };
        var town_stops = new Json.Array ();
        town_stops.add_int_element (8);
        town_stops.add_double_element (8);
        var town_stops2 = new Json.Array ();
        town_stops2.add_int_element (14);
        town_stops2.add_double_element (14);
        town_text_size.stops.add (town_stops);
        town_text_size.stops.add (town_stops2);

        var place_town = new Layer () {
            id = "place_town",
            kind = "symbol",
            source = "vector-tiles",
            source_layer = "place",
            minzoom = 8,
            maxzoom = 16,
            filter = place_town_filter,
            layout = new Layer.Layout () {
                text_anchor = "center",
                text_field = "{name_en}",
                text_font = { "Geist Regular" },
                text_max_width = 6,
                text_size = town_text_size
            },
            paint = new Layer.Paint () {
                text_color = TEXT_SECONDARY
            }
        };
        layers.add (place_town);

        // POI labels
        var poi_filter = new Notejot.Expression ("all");
        poi_filter.append_string_string ("==", "class", "park");

        var poi = new Layer () {
            id = "poi_park",
            kind = "symbol",
            source = "vector-tiles",
            source_layer = "poi",
            minzoom = 12,
            filter = poi_filter,
            layout = new Layer.Layout () {
                text_anchor = "center",
                text_field = "{name_en}",
                text_font = { "Geist Regular" },
                text_max_width = 6,
                text_size = new InterpolateExpression () {
                    base_val = 1
                }
            },
            paint = new Layer.Paint () {
                text_color = GREEN
            }
        };

        var poi_text_size = new InterpolateExpression () {
            base_val = 1
        };
        var poi_stops = new Json.Array ();
        poi_stops.add_int_element (12);
        poi_stops.add_double_element (8);
        var poi_stops2 = new Json.Array ();
        poi_stops2.add_int_element (16);
        poi_stops2.add_double_element (12);
        poi_text_size.stops.add (poi_stops);
        poi_text_size.stops.add (poi_stops2);
        poi.layout.text_size = poi_text_size;

        layers.add (poi);
    }

    public string to_string () {
        var generator = new Json.Generator () {
            root = Json.gobject_serialize (this)
        };

        return generator.to_data (null).replace ("kind", "type");
    }

    public class Sources : Object {
        public VectorTiles vector_tiles { get; private set; }

        construct {
            vector_tiles = new VectorTiles ();
        }

        public class VectorTiles : Notejot.JsonObject {
            public string kind { get; private set; default = "vector"; }
            public string[] tiles { get; private set; default = { "https://tileserver.gnome.org/data/v3/{z}/{x}/{y}.pbf" }; }
            public int maxzoom { get; private set; }
            public int minzoom { get; private set; }

            construct {
                minzoom = 0;
                maxzoom = 14;
            }
        }
    }

    // https://docs.maptiler.com/gl-style-specification/layers/
    public class Layer : Notejot.JsonObject {
        public string id { get; set; }
        public string kind { get; set; }
        public string source { get; set; }
        public string source_layer { get; set; }
        public int maxzoom { get; set; }
        public int minzoom { get; set; }

        public Expression filter { get; set; }
        public Layout layout { get; set; }
        public Paint paint { get; set; }

        // https://docs.maptiler.com/gl-style-specification/layers/#paint-property
        public class Paint : Notejot.JsonObject {
            public double fill_opacity { get; set; }
            public string background_color { get; set; }
            public bool fill_antialias { get; set; }
            public string fill_color { get; set; }
            public string fill_outline_color { get; set; }
            public string text_color { get; set; }
            public string line_color { get; set; }
            public double line_opacity { get; set; }
            public Json.Array line_dasharray { get; set; }
            public InterpolateExpression line_width { get; set; }
        }

        public class Layout : Notejot.JsonObject {
            public string line_cap { get; set; }
            public string line_join { get; set; }
            public string text_anchor { get; set; }
            public string text_field { get; set; }
            public string[] text_font { get; set; }
            public int text_max_width { get; set; }
            public Json.Array text_offset { get; set; }
            public InterpolateExpression text_size { get; set; }
            public string text_transform { get; set; }
            public bool icon_allow_overlap { get; set; }
            public bool icon_optional { get; set; }
        }
    }
}

// https://docs.maptiler.com/gl-style-specification/expressions/#interpolate
public class Notejot.InterpolateExpression : Notejot.JsonObject {
    public double base_val { get; set; } // Need to serialize as base
    public Gee.ArrayList<Json.Array> stops { get; set; }

    construct {
        stops = new Gee.ArrayList<Json.Array> (null);
    }
}

// https://docs.maptiler.com/gl-style-specification/expressions/
public class Notejot.Expression : Notejot.JsonObject {
    public string name { get; construct set; }
    public Gee.ArrayList<Json.Array> args { get; set; }

    public Expression (string name) {
        Object (name: name);
    }

    construct {
        args = new Gee.ArrayList<Json.Array> (null);
    }

    public void append_string_string (string operator, string arg1, string arg2) {
        var argument = new Json.Array ();
        argument.add_string_element (operator);
        argument.add_string_element (arg1);
        argument.add_string_element (arg2);
        args.add (argument);
    }

    public void append_string_int (string operator, string arg1, int arg2) {
        var argument = new Json.Array ();
        argument.add_string_element (operator);
        argument.add_string_element (arg1);
        argument.add_int_element (arg2);
        args.add (argument);
    }

    // FIXME: assertion 'self != NULL' failed
    public Json.Node serialize () {
        var array = new Json.Array ();

        array.add_string_element (name);

        foreach (var argument in args) {
            array.add_array_element (argument);
        }

        var node = new Json.Node (ARRAY);
        node.set_array (array);

        return node;
    }
}
