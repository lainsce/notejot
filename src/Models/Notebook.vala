namespace Notejot {
    public class Notebook : Object, Json.Serializable {
        public string id { get; set; default = Uuid.string_random (); }
        public string title { get; set; }

        public static Notebook from_json (Json.Node node) requires (node.get_node_type () == OBJECT) {
            return (Notebook) Json.gobject_deserialize (typeof (Notebook), node);
        }

        public static List<Notebook> list_from_json (Json.Node node) requires (node.get_node_type () == ARRAY) {
            var result = new List<Notebook> ();

            var json_array = node.get_array ();
            json_array.foreach_element ((_, __, element_node) => {
                result.append (Notebook.from_json (element_node));
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
