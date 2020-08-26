/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

[DBus (name = "org.freedesktop.systemd1.Manager")]
interface SystemDBus : Object {
    public abstract GLib.ObjectPath reload_or_try_restart_unit (string unit, string mode) throws GLib.Error;
}

public class LoginDHelper.Application : GLib.Application {
    private const uint ACTIVE_TIMEOUT_SECONDS = 5;
    private uint timeout_id = 0;
    private uint own_id = -1;

    construct {
        application_id = Power.LOGIND_HELPER_NAME;
    }

    private void on_bus_lost (DBusConnection connection, string name) {
        warning ("Could not acquire name: %s", name);
    }

    private void on_bus_acquired (DBusConnection connection) {
        var server = Server.get_default ();
        server.reset_timeout.connect (on_reset_timeout);

        try {
            connection.register_object (Power.LOGIND_HELPER_OBJECT_PATH, server);
        } catch (IOError e) {
            warning (e.message);
        }

        on_reset_timeout ();
    }

    private void on_reset_timeout () {
        if (timeout_id > 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add_seconds (ACTIVE_TIMEOUT_SECONDS, () => {
            timeout_id = 0;
            release ();
            return false;
        });
    }

    public override void activate () {
        own_id = Bus.own_name (BusType.SYSTEM, Power.LOGIND_HELPER_NAME, BusNameOwnerFlags.REPLACE,
                    on_bus_acquired,
                    null,
                    on_bus_lost);
        hold ();
    }

    public override void shutdown () {
        if (own_id != -1) {
            Bus.unown_name (own_id);
        }

        /* We need to restart systemd-logind to ensure that the lid settings are taken into account */
        try {
            var systemd_bus_proxy = Bus.get_proxy_sync<SystemDBus>  (BusType.SYSTEM, "org.freedesktop.systemd1", "/org/freedesktop/systemd1");
            systemd_bus_proxy.reload_or_try_restart_unit ("systemd-logind.service", "fail");
        } catch (Error e) {
            warning (e.message);
        }

        base.shutdown ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
