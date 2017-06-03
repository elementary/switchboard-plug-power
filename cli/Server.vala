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

[DBus (name = "org.freedesktop.DBus")]
private interface DBus : Object {
    [DBus (name = "GetConnectionUnixProcessID")]
    public abstract uint32 get_connection_unix_process_id (string name) throws IOError;
    
    public abstract uint32 get_connection_unix_user (string name) throws IOError;
}

[DBus (name = "io.elementary.logind.helper")]
public class LoginDHelper.Server : Object {
    private const string CONFIG_FILE = "/etc/systemd/logind.conf";
    private const string CONFIG_GROUP = "Login";
    private const string ACTION_ID = "org.pantheon.switchboard.power.administration";

    private KeyFile file;
    private DBus? bus_proxy = null;

    [DBus (visible = false)]
    public signal void reset_timeout ();

    public signal void changed ();

    private bool _present = false;
    public bool present { 
        get {
            reset_timeout ();
            return _present;
        }
    }

    private static Server? instance = null;

    [DBus (visible = false)]
    public static unowned Server get_default () {
        if (instance == null) {
            instance = new Server ();
        }

        return instance;
    }

    construct {
        file = new KeyFile ();

        try {
            bus_proxy = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DBus", "/");
        } catch (Error e) {
            warning (e.message);
            bus_proxy = null;
        }

        try {
            _present = file.load_from_file (CONFIG_FILE, KeyFileFlags.KEEP_COMMENTS);
        } catch (Error e) {
            warning (e.message);
        }
    }

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

    public string get_key (string key) throws Error {
        reset_timeout ();

        try {
            return file.get_string (CONFIG_GROUP, key);
        }  catch (Error e) {
            throw e;
        }
    }

    public string get_config_file () {
        reset_timeout ();
        return CONFIG_FILE;
    }

    private bool get_sender_is_authorized (BusName sender) {
        if (bus_proxy == null) {
            return false;
        }

        uint32 user = 0, pid = 0;

        try {
            pid = get_pid_from_sender (sender);
            user = bus_proxy.get_connection_unix_user (sender);
        } catch (Error e) {
            warning (e.message);
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

    private uint32 get_pid_from_sender (BusName sender) {
        uint32 pid = 0;

        try {
            pid = bus_proxy.get_connection_unix_process_id (sender);
        } catch (Error e) {
            warning (e.message);
        }   

        return pid;
    }    
}
