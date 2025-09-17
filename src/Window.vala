namespace Notejot {
    public class Window : He.ApplicationWindow {
        private const GLib.ActionEntry APP_ENTRIES[] = {
            { "edit-entry", on_edit_entry_clicked },
            { "delete-entry", on_delete_entry_clicked },
            { "restore-entry", on_restore_entry_clicked },
            { "sync-now", on_sync_now_clicked },
        };
        private DataManager data_manager;
        private InsightsView insights_view;
        private PlacesView places_view;

        private He.OverlayButton fab;
        private Gtk.Box main_content_container;
        private Sidebar sidebar;
        private EntriesView entries_view;
        private EmptyStateView empty_state_view;
        private DeletedEmptyStateView deleted_empty_state_view;
        private SettingsWindow? settings_window;

        private string? current_tag_uuid = null; // null means "All Entries" here
        private Entry? selected_entry = null; // Track the currently selected entry
        private EntryEditorView? entry_editor_view; // Integrated editor view

        public Window (He.Application app) {
            Object (application : app, title : _("Notejot"));
            this.data_manager = new DataManager ();

            this.set_default_size (1024, 800);

            var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.set_child (main_box);

            // --- Sidebar ---
            this.sidebar = new Sidebar (this.data_manager);
            this.sidebar.tag_selected.connect (on_tag_selected);
            this.sidebar.add_tag_clicked.connect (on_add_tag_clicked);
            this.sidebar.settings_clicked.connect (() => {
                if (this.settings_window == null) {
                    this.settings_window = new SettingsWindow (this, this.data_manager);
                    if (app != null) {
                        this.settings_window.set_application (app);
                        app.add_window (this.settings_window);
                    }
                    this.settings_window.close_request.connect (() => {
                        this.settings_window = null;
                        return false;
                    });
                }
                this.settings_window.present ();
            });
            this.sidebar.view_switched.connect (switch_to_view);
            main_box.append (this.sidebar);

            // --- Main Content Area Container ---
            this.main_content_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.main_content_container.set_hexpand (true);
            main_box.append (this.main_content_container);

            // --- Main Content Views ---
            this.entries_view = new EntriesView (this.data_manager);
            this.entries_view.entry_selected_for_edit.connect ((entry) => {
                this.selected_entry = entry;
                on_edit_entry_clicked ();
            });
            this.entries_view.entry_deleted.connect ((entry) => {
                this.selected_entry = entry;
                on_delete_entry_clicked ();
            });
            this.entries_view.entry_restored.connect ((entry) => {
                this.selected_entry = entry;
                on_restore_entry_clicked ();
            });
            this.entries_view.list_updated.connect ((count, search_query) => {
                if (count == 0) {
                    if (this.current_tag_uuid == "deleted") {
                        switch_to_view ("deleted-empty");
                    } else if (search_query == "") {
                        switch_to_view ("empty");
                    }
                } else {
                    switch_to_view ("entries");
                }
            });

            this.empty_state_view = new EmptyStateView ();
            this.empty_state_view.add_entry_clicked.connect (on_add_entry_clicked);
            this.deleted_empty_state_view = new DeletedEmptyStateView ();
            this.insights_view = new InsightsView (this.data_manager);
            this.places_view = new PlacesView (this.data_manager);

            // --- FAB (only for entries view) ---
            fab = new He.OverlayButton ("list-add-symbolic", null, null);
            fab.alignment = He.OverlayButton.Alignment.CENTER;
            fab.clicked.connect (on_add_entry_clicked);
            fab.child = this.entries_view;

            // Initially show entries view with FAB
            this.main_content_container.append (fab);
            refresh_sidebar_tags ();
            update_stats ();

            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (APP_ENTRIES, this);
            this.insert_action_group ("win", actions);

            this.present ();
        }

        private void switch_to_view (string view_name) {
            // Navigation guard: if leaving a dirty editor view, confirm discard
            if (view_name != "editor"
                && this.entry_editor_view != null
                && this.main_content_container.get_first_child () == this.entry_editor_view
                && this.entry_editor_view.is_dirty ()) {
                var dialog = new He.Window ();
                dialog.set_transient_for (this);
                dialog.set_title (_("Discard unsaved changes?"));
                dialog.add_css_class ("dialog-content");

                var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

                var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
                header_box.set_margin_top (12);
                header_box.set_margin_start (12);
                header_box.set_margin_end (12);
                header_box.set_margin_bottom (12);

                var title_label = new Gtk.Label (_("Discard Unsaved Changes")) { halign = Gtk.Align.START };
                title_label.add_css_class ("title-3");
                header_box.append (title_label);

                header_box.append (new Gtk.Label ("") { hexpand = true }); // spacer

                var close_button = new He.Button ("window-close-symbolic", "");
                close_button.is_disclosure = true;
                close_button.clicked.connect (() => {
                    dialog.close ();
                });
                header_box.append (close_button);

                var winhandle = new Gtk.WindowHandle ();
                winhandle.set_child (header_box);
                container.append (winhandle);

                var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
                content_box.set_margin_start (18);
                content_box.set_margin_end (18);
                content_box.set_margin_bottom (6);

                var message_label = new Gtk.Label (_("You have unsaved changes. Discard them?"));
                message_label.set_wrap (true);
                message_label.set_xalign (0.0f);
                content_box.append (message_label);
                container.append (content_box);

                var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
                buttons_box.set_margin_start (18);
                buttons_box.set_margin_end (18);
                buttons_box.set_margin_bottom (18);
                buttons_box.set_halign (Gtk.Align.END);

                var cancel_button = new He.Button ("", _("Cancel"));
                cancel_button.is_tint = true;
                cancel_button.clicked.connect (() => {
                    dialog.close ();
                });
                buttons_box.append (cancel_button);

                var discard_button = new He.Button ("", _("Discard"));
                discard_button.is_fill = true;
                discard_button.clicked.connect (() => {
                    this.entry_editor_view.clear_dirty ();
                    var current_child2 = this.main_content_container.get_first_child ();
                    if (current_child2 != null) {
                        this.main_content_container.remove (current_child2);
                    }
                    if (view_name == "entries") {
                        this.main_content_container.append (fab);
                        fab.child = this.entries_view;
                    } else if (view_name == "empty") {
                        this.main_content_container.append (this.empty_state_view);
                    } else if (view_name == "deleted-empty") {
                        this.main_content_container.append (this.deleted_empty_state_view);
                    } else if (view_name == "editor") {
                        if (this.entry_editor_view != null) {
                            this.main_content_container.append (this.entry_editor_view);
                        }
                    } else {
                        if (view_name == "insights") {
                            this.main_content_container.append (this.insights_view);
                        } else if (view_name == "places") {
                            this.main_content_container.append (this.places_view);
                        }
                    }
                    dialog.close ();
                });
                buttons_box.append (discard_button);

                container.append (buttons_box);

                dialog.set_child (container);
                dialog.present ();
                return;
            }
            var current_child = this.main_content_container.get_first_child ();
            if (current_child != null) {
                this.main_content_container.remove (current_child);
            }

            if (view_name == "entries") {
                this.main_content_container.append (fab);
                fab.child = this.entries_view;
            } else if (view_name == "empty") {
                this.main_content_container.append (this.empty_state_view);
            } else if (view_name == "deleted-empty") {
                this.main_content_container.append (this.deleted_empty_state_view);
            } else if (view_name == "editor") {
                if (this.entry_editor_view != null) {
                    this.main_content_container.append (this.entry_editor_view);
                }
            } else {
                if (view_name == "insights") {
                    this.main_content_container.append (this.insights_view);
                } else if (view_name == "places") {
                    this.main_content_container.append (this.places_view);
                }
            }
        }

        private void refresh_sidebar_tags () {
            this.sidebar.refresh_tags ();
        }

        private void on_tag_selected (string? tag_uuid, string display_name) {
            this.current_tag_uuid = tag_uuid;
            this.entries_view.set_current_tag (tag_uuid, display_name);
            this.empty_state_view.set_header_label (display_name);
            this.deleted_empty_state_view.set_header_label (display_name);
            refresh_entry_list ();
        }

        private void refresh_entry_list () {
            this.entries_view.refresh_list ();
        }

        private void update_stats () {
            this.sidebar.update_stats ();
            this.insights_view.update_view ();
            if (this.places_view != null)this.places_view.refresh_pins ();
        }

        private void open_entry_editor (Entry? entry) {
            if (this.entry_editor_view == null) {
                this.entry_editor_view = new EntryEditorView (this.data_manager);
                this.entry_editor_view.saved.connect (on_editor_saved);
                this.entry_editor_view.cancelled.connect (() => {
                    this.refresh_entry_list ();
                });
            }
            this.entry_editor_view.load_entry (entry);
            if (entry == null && this.current_tag_uuid != null && this.current_tag_uuid != "deleted") {
                this.entry_editor_view.preselect_tag (this.current_tag_uuid);
            }
            switch_to_view ("editor");
        }

        private void on_editor_saved (Entry? existing, bool is_new) {
            if (this.entry_editor_view == null)return;

            var title = this.entry_editor_view.title_entry.get_internal_entry ().text;
            Gtk.TextIter s, e;
            this.entry_editor_view.content_view.get_buffer ().get_bounds (out s, out e);
            var content = this.entry_editor_view.content_view.get_buffer ().get_text (s, e, false);
            var address = this.entry_editor_view.location_entry.get_internal_entry ().text;
            var tag_uuids = this.entry_editor_view.get_selected_tag_uuids ();

            if (this.current_tag_uuid != null && this.current_tag_uuid != "deleted") {
                bool found = false;
                foreach (var uuid in tag_uuids) {
                    if (uuid == this.current_tag_uuid) { found = true; break; }
                }
                if (!found) {
                    tag_uuids.append (this.current_tag_uuid);
                }
            }

            if (is_new) {
                var new_entry = new Entry (title, content, tag_uuids, null);
                new_entry.location_address = address;
                foreach (var p in this.entry_editor_view.image_paths) {
                    new_entry.image_paths.append (p);
                }
                save_entry_with_geocode.begin (new_entry, true);
            } else if (existing != null) {
                existing.title = title;
                existing.content = content;
                // Rebuild tag_uuids list instead of assigning (avoids duplicating GLib.List instance)
                existing.tag_uuids = new GLib.List<string> ();
                foreach (var u in tag_uuids) {
                    existing.tag_uuids.append (u);
                }
                existing.location_address = address;
                existing.modified_timestamp = new GLib.DateTime.now_utc ().to_unix ();
                // Rebuild and normalize image_paths: import to app media dir and store absolute paths
                existing.image_paths = new GLib.List<string> ();
                var app_dir = GLib.Path.build_filename (GLib.Environment.get_user_data_dir (), "io.github.lainsce.Notejot");
                var media_dir = GLib.Path.build_filename (app_dir, "media");
                GLib.DirUtils.create_with_parents (media_dir, 0755);
                foreach (var p in this.entry_editor_view.image_paths) {
                    if (p == null || p.strip () == "")continue;
                    string final_path = p;
                    try {
                        var file_base = GLib.Path.get_basename (p);
                        var dest = GLib.Path.build_filename (media_dir, existing.uuid + "_" + file_base);
                        var srcf = File.new_for_path (p);
                        var dstf = File.new_for_path (dest);
                        // Always overwrite to ensure the latest edit is saved in media dir
                        srcf.copy (dstf, FileCopyFlags.OVERWRITE, null, null);
                        final_path = dest;
                    } catch (Error e) {
                        // If copy fails, fall back to original path
                        final_path = p;
                    }
                    existing.image_paths.append (final_path);
                }
                save_entry_with_geocode.begin (existing, false);
            }

            this.refresh_entry_list ();
            if (this.entry_editor_view != null) {
                // Ensure editor is marked clean after save to prevent discard dialog
                this.entry_editor_view.clear_dirty ();
            }
        }

        private void on_add_tag_clicked () {
            var dialog = new AddTagDialog (this, false);
            dialog.present ();

            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    var name = dialog.name_entry.get_internal_entry ().text;
                    if (name != "") {
                        var new_tag = new Tag (name, dialog.get_selected_color (), dialog.get_selected_icon_name ());
                        this.data_manager.add_tag (new_tag);
                        this.data_manager.save_data ();
                        this.refresh_sidebar_tags ();
                    }
                }
                dialog.destroy ();
            });
        }

        private void save_entry_and_refresh (Entry entry, bool is_new_entry) {
            if (is_new_entry) {
                this.data_manager.add_entry (entry);
            }
            this.data_manager.save_data ();
            this.refresh_sidebar_tags ();
            this.refresh_entry_list ();
            this.update_stats ();
        }

        private async void save_entry_with_geocode (Entry entry, bool is_new_entry) {
            yield entry.geocode_location ();

            save_entry_and_refresh (entry, is_new_entry);
        }

        private void on_edit_entry_clicked () {
            if (this.selected_entry == null)return;
            open_entry_editor (this.selected_entry);
        }

        private void on_delete_entry_clicked () {
            if (this.selected_entry == null)return;
            var entry = this.selected_entry;

            if (this.current_tag_uuid == "deleted") {
                // Permanently delete if in trash
                var dialog = new He.Window ();
                dialog.set_transient_for (this);
                dialog.set_modal (true);
                dialog.add_css_class ("dialog-content");

                var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

                var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
                header_box.set_margin_top (12);
                header_box.set_margin_start (12);
                header_box.set_margin_end (12);
                header_box.set_margin_bottom (12);

                var title_label = new Gtk.Label (_("Permanently Delete This Entry?")) { halign = Gtk.Align.START };
                title_label.add_css_class ("title-3");
                header_box.append (title_label);

                header_box.append (new Gtk.Label ("") { hexpand = true }); // spacer

                var close_button = new He.Button ("window-close-symbolic", "");
                close_button.is_disclosure = true;
                close_button.clicked.connect (() => {
                    dialog.close ();
                });
                header_box.append (close_button);

                var winhandle = new Gtk.WindowHandle ();
                winhandle.set_child (header_box);
                container.append (winhandle);

                var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
                content_box.set_margin_start (18);
                content_box.set_margin_end (18);
                content_box.set_margin_bottom (6);

                var message_label = new Gtk.Label (_("Deleting this entry from trash will permanently remove it from Notejot."));
                message_label.set_wrap (true);
                message_label.set_xalign (0.0f);
                content_box.append (message_label);
                container.append (content_box);

                var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
                buttons_box.set_margin_start (18);
                buttons_box.set_margin_end (18);
                buttons_box.set_margin_bottom (18);
                buttons_box.set_halign (Gtk.Align.END);

                var cancel_button = new He.Button ("", _("Cancel"));
                cancel_button.is_tint = true;
                cancel_button.clicked.connect (() => {
                    dialog.close ();
                });
                buttons_box.append (cancel_button);

                var discard_button = new He.Button ("", _("Discard"));
                discard_button.is_fill = true;
                discard_button.custom_color = He.Colors.RED;
                discard_button.clicked.connect (() => {
                    this.data_manager.permanently_delete_entry (entry);
                    this.data_manager.save_data ();
                    this.refresh_sidebar_tags ();
                    this.refresh_entry_list ();
                    this.update_stats ();
                    dialog.close ();
                });
                buttons_box.append (discard_button);

                container.append (buttons_box);

                dialog.set_child (container);
                dialog.present ();
            } else {
                // Move to trash
                this.data_manager.delete_entry (entry);
                this.data_manager.save_data ();
                this.refresh_sidebar_tags ();
                this.refresh_entry_list ();
                this.update_stats ();
            }
        }

        private void on_restore_entry_clicked () {
            if (this.selected_entry == null)return;
            this.data_manager.restore_entry (this.selected_entry);
            this.data_manager.save_data ();
            this.refresh_sidebar_tags ();
            this.refresh_entry_list ();
            this.update_stats ();
        }

        private void on_sync_now_clicked () {
            this.data_manager.sync_push ();
            this.refresh_sidebar_tags ();
            this.refresh_entry_list ();
            this.update_stats ();
        }

        public void open_new_entry () {
            // Don't allow adding entries when in "Recently Deleted" section
            if (this.current_tag_uuid == "deleted") {
                return;
            }
            open_entry_editor (null);
        }

        private void on_add_entry_clicked () {
            open_new_entry ();
        }
    }
}
