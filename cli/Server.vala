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

[DBus (name = "io.elementary.logind.helper")]
public class LoginDHelper.Server : Object {
    [DBus (visible = false)]
    public signal void reset_timeout ();

    /**
     * changed:
     *
     * Emitted when a call to set_key () succeeded
     */
    public signal void changed ();

    private const string CONFIG_FILE = "/etc/systemd/logind.conf";
    private const string CONFIG_GROUP = "Login";
    private const string ACTION_ID = "org.pantheon.switchboard.power.administration";

    private KeyFile file;

    private bool _present = false;
    public bool present { 
        get {
            reset_timeout ();
            return _present;
        }
    }

    private static Server? instance = null;
    private static Power.DBus? bus_proxy = null;

    [DBus (visible = false)]
    public static unowned Server get_default () {
        if (instance == null) {
            instance = new Server ();
        }

        return instance;
    }

    static construct {
        try {
            bus_proxy = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DBus", "/");
        } catch (Error e) {
            warning (e.message);
            bus_proxy = null;
        }        
    }

    construct {
        file = new KeyFile ();

        try {
            _present = file.load_from_file (CONFIG_FILE, KeyFileFlags.KEEP_COMMENTS);
        } catch (Error e) {
            warning (e.message);
        }
    }

    /**
     * set_key:
     * @key: the key to set
     * @value: the value that key will be set with
     *
     * Sets the @key to @value in the logind config file (that is /etc/systemd/logind.conf)
     *
     * In order for this method to succeed, the caller must be already granted the 
     * org.pantheon.switchboard.power.administration policy PolicyKit permission, otherwise
     * the method will throw an error and exit
     *
     * When the @key was successfully set, the changed () signal will be emitted
     */
    public void set_key (string key, string value, BusName sender) throws Error {
        reset_timeout ();

        if (!get_sender_is_authorized (sender)) {
            throw new IOError.PERMISSION_DENIED ("Error: sender not authorized");
        }

        file.set_string (CONFIG_GROUP, key, value);

        try {
            file.save_to_file (CONFIG_FILE);
            changed ();
        } catch (Error e) {
            throw e;
        }
    }

    /**
     * get_key:
     * @key: the key to retrieve
     *
     * Returns the value of @key in the logind config file (that is /etc/systemd/logind.conf)
     *
     * If the @key does not exist, an error will be thrown
     *
     * Returns: the value for the @key
     */
    public string get_key (string key) throws Error {
        reset_timeout ();

        try {
            return file.get_string (CONFIG_GROUP, key);
        }  catch (Error e) {
            throw e;
        }
    }

    /**
     * get_config_file:
     *
     * Gets a full path to the current used logind config file (at the moment this
     * will always return "/etc/systemd/logind.conf")
     */
    public string get_config_file () {
        reset_timeout ();
        return CONFIG_FILE;
    }

    private static bool get_sender_is_authorized (BusName sender) {
        if (bus_proxy == null) {
            return false;
        }

        uint32 user = 0, pid = 0;

        try {
            pid = bus_proxy.get_connection_unix_process_id (sender);
            user = bus_proxy.get_connection_unix_user (sender);
        } catch (Error e) {
            warning (e.message);
            return false;
        }            

        var subject = new Polkit.UnixProcess.for_owner ((int)pid, 0, (int)user);

        try {
            var authority = Polkit.Authority.get_sync (null);
            var auth_result = authority.check_authorization_sync (subject, ACTION_ID, null, Polkit.CheckAuthorizationFlags.NONE);
            return auth_result.get_is_authorized ();
        } catch (Error e) {
            warning (e.message);
        }

        return false;
    } 
}
