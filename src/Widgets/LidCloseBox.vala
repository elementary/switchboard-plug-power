/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class LidCloseBox : Gtk.Grid {
    public Gtk.SizeGroup size_group { get; construct; }

    public LidCloseBox (Gtk.SizeGroup size_group) {
        Object (size_group: size_group);
    }

    construct {
        string[] strings = {
            "blank",
            _("Suspend"),
            _("Shutdown"),
            _("Hibernate"),
            _("Ask to shutdown"),
            _("Do nothing"),
            _("Log Out")
        };

        var header_label = new Granite.HeaderLabel (_("Lid Close Behavior"));

        var ac_dropdown = new Gtk.DropDown.from_strings (strings) {
            hexpand = true
        };

        var ac_label = new Gtk.Label (_("When Plugged In")) {
            mnemonic_widget = ac_dropdown,
            xalign = 0
        };

        var battery_dropdown = new Gtk.DropDown.from_strings (strings) {
            hexpand = true
        };

        var battery_label = new Gtk.Label (_("On Battery")) {
            mnemonic_widget = battery_dropdown,
            xalign = 0
        };

        var external_display_switch = new Gtk.Switch () {
            halign = END,
        };

        var external_display_label = new Gtk.Label (_("Ignore With External Display")) {
            mnemonic_widget = external_display_switch,
            xalign = 0
        };

        row_spacing = 6;
        column_spacing = 12;
        attach (header_label, 0, 0, 2);
        attach (ac_label, 0, 1);
        attach (ac_dropdown, 1, 1);
        attach (battery_label, 0, 2);
        attach (battery_dropdown, 1, 2);
        attach (external_display_label, 0, 3);
        attach (external_display_switch, 1, 3);

        size_group.add_widget (ac_label);
        size_group.add_widget (battery_label);
        size_group.add_widget (external_display_label);

        var settings = new Settings ("org.gnome.settings-daemon.plugins.power");
        settings.bind ("lid-close-suspend-with-external-monitor", external_display_switch, "active", INVERT_BOOLEAN);

        settings.bind_with_mapping ("lid-close-ac-action", ac_dropdown, "selected", DEFAULT,
            get_mapping, set_mapping, null, null
        );

        settings.bind_with_mapping ("lid-close-battery-action", battery_dropdown, "selected", DEFAULT,
            get_mapping, set_mapping, null, null
        );

    }

    public static bool get_mapping (Value value, Variant variant) {
        switch (variant.get_string ()) {
            case "blank":
                value.set_uint (0);
                break;
            case "suspend":
                value.set_uint (1);
                break;
            case "shutdown":
                value.set_uint (2);
                break;
            case "hibernate":
                value.set_uint (3);
                break;
            case "interactive":
                value.set_uint (4);
                break;
            case "nothing":
                value.set_uint (5);
                break;
            case "logout":
                value.set_uint (6);
                break;
        }

        return true;
    }

    public static Variant set_mapping (Value value, VariantType expected_type) {
        switch (value.get_uint ()) {
            case 0:
                return new Variant.string ("blank");
            case 1:
                return new Variant.string ("suspend");
            case 2:
                return new Variant.string ("shutdown");
            case 3:
                return new Variant.string ("hibernate");
            case 4:
                return new Variant.string ("interactive");
            case 5:
                return new Variant.string ("nothing");
            case 6:
                return new Variant.string ("logout");
        }

        return new Variant.string ("blank");
    }
}
