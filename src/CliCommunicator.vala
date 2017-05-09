/*
 * Copyright (c) 2011-2016 elementary LLC. (https://launchpad.net/switchboard-plug-power)
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

namespace Power {
    public class CliCommunicator {

        public bool supported { get; private set; }
        public Action lid_close { get; private set; }
        public Action lid_close_dock { get; private set; }

        public signal void changed ();

        public enum Action {
            IGNORE,
            POWEROFF,
            LOCK,
            SUSPEND,
            HALT,
            NOT_SUPPORTED
        }

        public CliCommunicator () {
            get_state ();
        }

        private string action_to_string (Action value) {
            string str = "NOT_SUPPORTED";
            switch (value) {
                case Action.IGNORE:
                    str = "ignore";
                    break;
                case Action.POWEROFF:
                    str = "poweroff";
                    break;
                case Action.LOCK:
                    str = "lock";
                    break;
                case Action.SUSPEND:
                    str = "suspend";
                    break;
                case Action.HALT:
                    str = "halt";
                    break;
                default:
                    break;
            }

            return str;
        }

        private Action string_to_action (string value) {
            Action action = Action.NOT_SUPPORTED;
            switch (value) {
                case "ignore":
                    action = Action.IGNORE;
                    break;
                case "poweroff":
                    action = Action.POWEROFF;
                    break;
                case "lock":
                    action = Action.LOCK;
                    break;
                case "suspend":
                    action = Action.SUSPEND;
                    break;
                case "halt":
                    action = Action.HALT;
                    break;
                default:
                    break;
            }

            return action;
        }

        private void seperate_string (string value) {
            string[] arg = value.split(":");

            if (arg[0].contains("supported")) {
                supported = true;
            } else if (arg[0].contains("not supported")) {
                supported = false;
            }

            if (arg[1].contains("dock")) {
                debug ("lid_close_dock:%s",arg[2]);
                lid_close_dock = string_to_action (arg[2]);
            }

            if (arg[3].contains("lid")) {
                debug ("lid_close:%s",arg[4]);
                lid_close = string_to_action (arg[4]);
            }

        }

        public void get_state () {
            string output = "";
            int status = 255; //no error

            try {
                var cli = "%s/systemd".printf (Build.PKGDATADIR);
                Process.spawn_sync (null, {cli, "show"},
                                    Environ.get (),
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    out output,
                                    null,
                                    out status);
                seperate_string (output);
            } catch (Error e) {
                warning (e.message);
            }
        }

        public void set_action_state (Action new_state, bool lid_dock) {
            if (permission.allowed) {
                string lid_keyword;
                string arg;
                string output;
                int status;

                if (lid_dock) {
                    lid_keyword = "dock_action";
                    arg = action_to_string (new_state);
                } else {
                    lid_keyword = "lid_action";
                    arg = action_to_string (new_state);
                }

                try {
                    string cli = "%s/systemd".printf (Build.PKGDATADIR);
                    debug (cli + lid_keyword + arg);
                    Process.spawn_sync (null, {"pkexec", cli, lid_keyword, arg},
                                        Environ.get (),
                                        SpawnFlags.SEARCH_PATH,
                                        null,
                                        out output,
                                        null,
                                        out status);

                    if (output.contains("success")) {

                        if (lid_dock) {
                            lid_close_dock = new_state;
                        } else {
                            lid_close = new_state;
                        }

                        changed ();
                    }  else {
                        warning ("setting new state not succeded output:%s", output);
                    }
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }
    }
}
