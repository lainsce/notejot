/*
* Copyright (C) 2017-2021 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
namespace Notejot {
    public class Trash : Object, Json.Serializable {
        public string id { get; set; default = Uuid.string_random (); }
        public string title { get; set; }
        public string subtitle { get; set; }
        public string text { get; set; }
        public string color { get; set; }
        public string notebook { get; set; }
        public string picture { get; set; }
        public bool pinned { get; set; }

        public static Trash from_json (Json.Node node) requires (node.get_node_type () == OBJECT) {
            return (Trash) Json.gobject_deserialize (typeof (Trash), node);
        }

        public static List<Trash> list_from_json (Json.Node node) requires (node.get_node_type () == ARRAY) {
            var result = new List<Trash> ();

            var json_array = node.get_array ();
            json_array.foreach_element ((_, __, element_node) => {
                result.append (Trash.from_json (element_node));
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
