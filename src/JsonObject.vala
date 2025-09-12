/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Notejot.JsonObject : Object, Json.Serializable {
    public override Json.Node serialize_property (string prop, Value val, ParamSpec spec) {
        var type = spec.value_type;

        if (type.is_a (typeof (Notejot.Expression))) {
            var expression = (Notejot.Expression) val;
            return expression.serialize ();
        }

        if (type.is_a (typeof (Gee.ArrayList))) {
            return serialize_list (prop, val, spec);
        }

        return default_serialize_property (prop, val, spec);
    }

    private static Json.Node serialize_list (string prop, Value val, ParamSpec spec) {
        var list = (Gee.ArrayList<Object>) val;
        if (list == null) {
            return new Json.Node (NULL);
        }

        var array = new Json.Array ();
        foreach (var object in list) {
            array.add_element (Json.gobject_serialize (object));
        }

        var node = new Json.Node (ARRAY);
        node.set_array (array);

        return node;
    }
}
