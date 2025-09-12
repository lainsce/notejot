// https://openmaptiles.org/docs/style/mapbox-gl-style-spec/
// https://openmaptiles.org/schema/
public class Notejot.MapStyle : Notejot.JsonObject {
    public int version { get; private set; }
    public string name { get; construct set; }
    public Sources sources { get; private set; }
    public Gee.ArrayList<Layer> layers { get; private set; }

    // Colors from style.css
    private const string YELLOW_300 = "#ffd54f";
    private const string BLUE_100 = "#64b5f6";
    private const string GREEN_100 = "#81c784";

    public MapStyle (string name) {
        Object (name: name);
    }

    construct {
        version = 8;
        sources = new Sources ();

        var background = new Layer () {
            id = "background",
            kind = "background",
            paint = new Layer.Paint () {
                background_color = GREEN_100
            }
        };

        var water_filter = new Notejot.Expression ("all");
        water_filter.append_string_string ("!=", "brunnel", "tunnel");

        var water = new Layer () {
            id = "water",
            kind = "fill",
            source = "vector-tiles",
            source_layer = "water",
            filter = water_filter,
            paint = new Layer.Paint () {
                fill_color = BLUE_100
            }
        };

        var place_city_filter = new Notejot.Expression ("all");
        place_city_filter.append_string_string ("==", "class", "city");

        var place_city = new Layer () {
            id = "place_city",
            kind = "symbol",
            source = "vector-tiles",
            source_layer = "place",
            minzoom = 2,
            maxzoom = 14,
            filter = place_city_filter,
            layout = new Layer.Layout () {
                text_anchor = "bottom",
                text_field = "{name_en}",
                text_font = { "Geist Medium" },
                text_max_width = 8,
                text_offset = { 0, 0 },
                icon_allow_overlap = true,
                icon_optional = false
            },
            paint = new Layer.Paint () {
                text_color = "#8a8a8e"
            }
        };

        layers = new Gee.ArrayList<Layer> (null);
        layers.add (background);
        layers.add (water);
        layers.add (place_city);
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
            public double[] line_dasharray { get; set; }
            public InterpolateExpression line_width { get; set; }
        }

        public class Layout : Notejot.JsonObject {
            public string line_cap { get; set; }
            public string line_join { get; set; }
            public string text_anchor { get; set; }
            public string text_field { get; set; }
            public string[] text_font { get; set; }
            public int text_max_width { get; set; }
            public double[] text_offset { get; set; }
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
