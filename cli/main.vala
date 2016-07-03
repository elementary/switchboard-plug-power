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

    private Systemd systemd;

    public static int main (string[] args) {
        systemd = new Systemd ();
        
        if (!systemd.present) {
            printerr ("Systemd is not present\n");
            return Posix.EXIT_FAILURE;
        }

        if (args.length < 2) {
            printerr ("command are needed: show / lid_action <action> / dock_action <action>\n");
            return Posix.EXIT_FAILURE;
        }
                
        if (args[1] == "show") {
            print_supported ();
            print ("dock:"+systemd.get_current_lid_close_dock_action ()+":\n");
            print ("lid:"+systemd.get_current_lid_close_action ()+":\n");
        } else if (args.length > 2) {
            var uid = Posix.getuid ();

            if (uid > 0) {
                printerr ("Must be run from administrative context\n");
                return Posix.EXIT_FAILURE;
            }

            if (args[1] == "lid_action") {
                if(systemd.set_lid_close_action (args[2])) {
                    print ("succes\n");
                }
            } else if (args[1] == "dock_action") {
                if(systemd.set_lid_close_dock_action (args[2])) {
                    print ("succes\n");
                } 
            }
        }

        return Posix.EXIT_SUCCESS;
    }

    private void print_supported () {
        if (!systemd.present) {
            print ("not supported:\n");
        } else {
            print ("supported:\n");
        }
    }
}