namespace Notejot {
    public class AddEntryDialog : He.Window {

        public He.TextField title_entry { get; private set; }
        public Gtk.TextView content_view { get; private set; }
        public He.TextField location_entry { get; private set; }
        public unowned GLib.List<string> image_paths { get; set; }

        private Gtk.FlowBox image_preview_box;
        private He.Button add_image_button;
        private GLib.List<Gtk.CheckButton> tag_check_buttons = new GLib.List<Gtk.CheckButton> ();
        private GLib.List<string> tag_uuids = new GLib.List<string> ();

        public signal void accepted();
        public signal void cancelled();
        public signal void response(int response_id);

        public AddEntryDialog(Gtk.Window parent, DataManager data_manager, Entry? entry) {
            Object(
                   parent : parent,
                   resizable: false
            );
            add_css_class("dialog-content");
            this.image_paths = new GLib.List<string> ();

            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.set_child(main_box);
            // --- Header with close button ---
            var header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            header_box.set_margin_top(12);
            header_box.set_margin_start(12);
            header_box.set_margin_end(12);

            var title_label = new Gtk.Label(entry == null ? _("Add New Entry") : _("Edit Entry"));
            title_label.add_css_class("title-3");
            header_box.append(title_label);
            var winhandle = new Gtk.WindowHandle();
            winhandle.set_child(header_box);
            main_box.append(winhandle);

            header_box.append(new Gtk.Label("") { hexpand = true });
            // Spacer
            var close_button = new He.Button("window-close-symbolic", "");
            close_button.is_disclosure = true;
            close_button.clicked.connect(() => {
                cancelled();
                response(Gtk.ResponseType.CANCEL);
                this.close();
            });
            header_box.append(close_button);

            // --- Two-column layout ---
            var two_column_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            two_column_box.set_margin_top(12);
            two_column_box.set_margin_bottom(12);
            two_column_box.set_margin_start(12);
            two_column_box.set_margin_end(12);
            two_column_box.vexpand = true;
            main_box.append(two_column_box);
            this.set_default_size(800, 600);
            // --- Left Column: Title & Content ---
            var left_column = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            left_column.hexpand = true;
            left_column.vexpand = true;
            left_column.set_size_request(400, -1);
            two_column_box.append(left_column);

            var content_card = new Gtk.Frame(_("Entry Details"));
            content_card.add_css_class("card");
            left_column.append(content_card);
            var content_card_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            content_card_box.set_margin_top(15);
            content_card_box.set_margin_bottom(15);
            content_card_box.set_margin_start(15);
            content_card_box.set_margin_end(15);
            content_card.set_child(content_card_box);
            this.title_entry = new He.TextField() { placeholder_text = _("Entry Title") };
            title_entry.get_internal_entry().text = entry == null ? "" : entry.title;
            content_card_box.append(this.title_entry);
            var scrolled_content = new Gtk.ScrolledWindow() { vexpand = true };
            scrolled_content.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            content_card_box.append(scrolled_content);
            this.content_view = new Gtk.TextView() {
                wrap_mode = Gtk.WrapMode.WORD_CHAR,
                left_margin = 8, right_margin = 8, top_margin = 8, bottom_margin = 8
            };
            this.content_view.add_css_class("text-view");
            this.content_view.get_buffer().text = entry == null ? "" : entry.content;
            scrolled_content.set_child(this.content_view);
            // --- Right Column: Tags, Location, Images ---
            var right_column = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            right_column.hexpand = true;
            right_column.vexpand = true;
            right_column.homogeneous = true;
            right_column.set_size_request(400, -1);
            two_column_box.append(right_column);
            // --- Tags Card ---
            var tags_card = new Gtk.Frame(_("Tags"));
            tags_card.add_css_class("card");
            right_column.append(tags_card);

            var tags_card_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            tags_card_box.set_margin_top(15);
            tags_card_box.set_margin_bottom(15);
            tags_card_box.set_margin_start(15);
            tags_card_box.set_margin_end(15);
            tags_card.set_child(tags_card_box);

            var scrolled_tags = new Gtk.ScrolledWindow();
            scrolled_tags.vexpand = true;
            scrolled_tags.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            tags_card_box.append(scrolled_tags);
            var tags_flowbox = new Gtk.FlowBox() {
                selection_mode = Gtk.SelectionMode.NONE,
                valign = Gtk.Align.START,
                max_children_per_line = 4
            };
            scrolled_tags.set_child(tags_flowbox);

            foreach (var tag in data_manager.get_tags()) {
                var check = new Gtk.CheckButton.with_label(tag.name);
                this.tag_check_buttons.append(check);
                this.tag_uuids.append(tag.uuid);
                tags_flowbox.insert(check, -1);
            }

            if (entry != null) {
                foreach (var tag in entry.tag_uuids) {
                    for (int i = 0; i < this.tag_uuids.length(); i++) {
                        var tag_uuid = this.tag_uuids.nth_data(i);
                        if (tag == tag_uuid) {
                            var check_button = this.tag_check_buttons.nth_data(i);
                            check_button.set_active(true);
                            break;
                        }
                    }
                }
            }

            // --- Location Card ---
            var location_card = new Gtk.Frame(_("Location"));
            location_card.add_css_class("card");
            right_column.append(location_card);

            var location_card_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            location_card_box.set_margin_top(15);
            location_card_box.set_margin_bottom(15);
            location_card_box.set_margin_start(15);
            location_card_box.set_margin_end(15);
            location_card.set_child(location_card_box);

            var location_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            location_card_box.append(location_box);
            this.location_entry = new He.TextField() { support_text = _("City, State, Country"), hexpand = true };
            this.location_entry.get_internal_entry().text = entry.location_address == null ? "" : entry.location_address;
            location_box.append(this.location_entry);

            // --- Images Card ---
            var images_card = new Gtk.Frame(_("Images (Max 4)"));
            images_card.add_css_class("card");
            right_column.append(images_card);

            var images_card_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            images_card_box.set_margin_top(15);
            images_card_box.set_margin_bottom(15);
            images_card_box.set_margin_start(15);
            images_card_box.set_margin_end(15);
            images_card.set_child(images_card_box);

            var image_toolbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            images_card_box.append(image_toolbar);
            this.add_image_button = new He.Button("", _("Add Images"));
            this.add_image_button.is_fill = true;
            this.add_image_button.clicked.connect(on_add_images_clicked);
            image_toolbar.append(this.add_image_button);
            this.image_preview_box = new Gtk.FlowBox() { min_children_per_line = 4, max_children_per_line = 4 };
            images_card_box.append(this.image_preview_box);
            if (entry != null) {
                for (var i = 0; i < entry.image_paths.length(); i++) {
                    if (entry.image_paths.length() >= 4) {
                        this.add_image_button.set_sensitive(false);
                    }
                    var picture = new Gtk.Picture.for_filename(entry.image_paths.nth_data(i));
                    picture.set_halign(Gtk.Align.CENTER);
                    picture.set_can_shrink(true);
                    this.image_preview_box.insert(picture, -1);
                }
            }

            // --- Button Box at bottom ---
            var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            button_box.set_halign(Gtk.Align.END);
            button_box.set_margin_bottom(12);
            button_box.set_margin_start(12);
            button_box.set_margin_end(12);
            main_box.append(button_box);

            var cancel_button = new He.Button("", _("Cancel"));
            cancel_button.is_tint = true;
            cancel_button.clicked.connect(() => {
                cancelled();
                response(Gtk.ResponseType.CANCEL);
                this.close();
            });
            button_box.append(cancel_button);

            var save_button = new He.Button("", _("Save"));
            save_button.is_fill = true;
            save_button.clicked.connect(() => {
                accepted();
                response(Gtk.ResponseType.ACCEPT);
                this.close();
            });
            button_box.append(save_button);
        }

        public string get_content() {
            var buffer = this.content_view.get_buffer();
            Gtk.TextIter start_iter, end_iter;
            buffer.get_bounds(out start_iter, out end_iter);
            return buffer.get_text(start_iter, end_iter, false);
        }

        public GLib.List<string> get_selected_tag_uuids() {
            var selected_uuids = new GLib.List<string> ();
            for (int i = 0; i < this.tag_check_buttons.length(); i++) {
                var button = this.tag_check_buttons.nth_data(i);
                if (button.get_active()) {
                    selected_uuids.append(this.tag_uuids.nth_data(i));
                }
            }
            return selected_uuids;
        }

        public void set_preselected_tags(GLib.List<string> selected_tag_uuids) {
            for (int i = 0; i < this.tag_uuids.length(); i++) {
                var tag_uuid = this.tag_uuids.nth_data(i);
                var check_button = this.tag_check_buttons.nth_data(i);

                foreach (var selected_uuid in selected_tag_uuids) {
                    if (tag_uuid == selected_uuid) {
                        check_button.set_active(true);
                        break;
                    }
                }
            }
        }

        private void on_add_images_clicked() {
            var file_dialog = new Gtk.FileDialog();
            file_dialog.set_title(_("Select Images"));
            file_dialog.set_accept_label(_("Open"));

            var filter = new Gtk.FileFilter();
            filter.set_filter_name(_("Image Files"));
            filter.add_pixbuf_formats();
            var filter_list = new GLib.ListStore(typeof(Gtk.FileFilter));
            filter_list.append(filter);
            file_dialog.set_filters(filter_list);

            file_dialog.open_multiple.begin((Gtk.Window) this.get_ancestor(typeof (Gtk.Window)), null, (obj, res) => {
                try {
                    var files = file_dialog.open_multiple.end(res);
                    for (var i = 0; i < files.get_n_items(); i++) {
                        if (this.image_paths.length() >= 4) {
                            break;
                        }
                        var file = files.get_item(i) as File;
                        this.image_paths.append(file.get_path());
                        var picture = new Gtk.Picture.for_filename(file.get_path());
                        picture.set_halign(Gtk.Align.CENTER);
                        picture.set_can_shrink(true);
                        this.image_preview_box.insert(picture, -1);
                    }

                    if (this.image_paths.length() >= 4) {
                        this.add_image_button.set_sensitive(false);
                    }
                } catch (Error e) {
                    // User cancelled or error occurred
                }
            });
        }
    }
}
