namespace Notejot.MiscUtils {
    public T find_ancestor_of_type<T> (Gtk.Widget? ancestor) {
      while ((ancestor = ancestor.get_parent ()) != null) {
        if (ancestor.get_type ().is_a (typeof (T)))
          return (T) ancestor;
      }

      return null;
    }
}
