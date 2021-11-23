class Notejot.NoteSorter : Gtk.Sorter {
  protected override Gtk.Ordering compare (Object? item1, Object? item2) {
    var note1 = item1 as Log;
    var note2 = item2 as Log;

    if (note1 == null || note2 == null)
      return EQUAL;

    if (note1.pinned && !note2.pinned) {
        return SMALLER;
    } else {
        return Gtk.Ordering.from_cmpfunc (note2.subtitle.collate (note1.subtitle));
    }
  }

  protected override Gtk.SorterOrder get_order () {
    return TOTAL;
  }
}
