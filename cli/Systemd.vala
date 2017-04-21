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
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

namespace systemd {
    public class Systemd : GLib.Object {

        private const string CONFIG_FILE = "/etc/systemd/logind.conf";
        private KeyFile file;

        public bool present { get; private set;}

        construct {
            file = new KeyFile ();
            try {
                present = file.load_from_file (CONFIG_FILE, KeyFileFlags.KEEP_COMMENTS);
            } catch (Error e) { }
        }

        public void set_key (string keyname, string val) {
            file.set_string ("Login", keyname, val);
            try {
                file.save_to_file (CONFIG_FILE);
            } catch (Error e) { }
        }

        public string get_key (string keyname) {
            try {
            return file.get_string ("Login", keyname);
            }  catch (Error e) { return ""; } 
        }
    }
}
