/*
 * Copyright (c) 2011-2015 elementary Developers (https://launchpad.net/elementary)
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

public class LoginDHelper.Application : GLib.Application {
    private const string IFACE_NAME = "io.elementary.logind.helper";
    private const string OBJECT_PATH = "/io/elementary/logind/helper";

    private const uint ACTIVE_TIMEOUT_SECONDS = 5;
    private uint timeout_id = 0;
    private uint own_id = -1;

    construct {
        application_id = IFACE_NAME;
    }

    private void on_bus_lost (DBusConnection connection, string name) {
        warning ("Could not acquire name: %s", name);
    }

    private void on_bus_acquired (DBusConnection connection) {
        var server = Server.get_default ();
        server.reset_timeout.connect (on_reset_timeout);

        try {
            connection.register_object (OBJECT_PATH, server);
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
        own_id = Bus.own_name (BusType.SYSTEM, IFACE_NAME, BusNameOwnerFlags.REPLACE,
                    on_bus_acquired,
                    () => {},
                    on_bus_lost);
        hold ();
    }

    public override void shutdown () {
        if (own_id != -1) {
            Bus.unown_name (own_id);
        }

        base.shutdown ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
