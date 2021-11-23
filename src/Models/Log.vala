namespace Notejot {
    public class Log : Object, Json.Serializable {
        public string id { get; set; default = Uuid.string_random (); }
        public string title { get; set; }
        public string subtitle { get; set; }
        public string text { get; set; }
        public string color { get; set; }
        public string notebook { get; set; }
        public bool pinned { get; set; }

        public static Log from_json (Json.Node node) requires (node.get_node_type () == OBJECT) {
            return (Log) Json.gobject_deserialize (typeof (Log), node);
        }

        public static List<Log> list_from_json (Json.Node node) requires (node.get_node_type () == ARRAY) {
            var result = new List<Log> ();

            var json_array = node.get_array ();
            json_array.foreach_element ((_, __, element_node) => {
                result.append (Log.from_json (element_node));
            });

            return (owned) result;
        }

        public Json.Node to_json () {
            return Json.gobject_serialize (this);
        }

        bool deserialize_property (string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {
            return default_deserialize_property (property_name, out @value, pspec, property_node);
        }

        Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
            return default_serialize_property (property_name, @value, pspec);
        }
    }
}
