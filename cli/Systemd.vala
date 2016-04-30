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
    public class Systemd {

        private const string CONFIG_FILE = "/etc/systemd/logind.conf";
        private const string LID_CLOSE = "HandleLidSwitch";
        private const string LID_CLOSE_DOCK = "HandleLidSwitchDocked";

        public bool present { get; private set;}

        public Systemd () {
            present = check_config_file ();

        }

        public string get_current_lid_close_dock_action () {
            if (present) {
                return  get_keyword_out_config_file (LID_CLOSE_DOCK, true);
            } else {
                return "not_supported";
            }
        }

        public string get_current_lid_close_action () {
            if (present) {
                return  get_keyword_out_config_file (LID_CLOSE, false);
            } else {
                return "not_supported";
            }
        }

        public bool set_lid_close_dock_action (string action) {
            if (present) {
                return set_keyword_action (LID_CLOSE_DOCK, action);
            } else {
                return false;
            }
        }

        public bool set_lid_close_action (string action) {
            if (present) {
                return set_keyword_action (LID_CLOSE, action);
            } else {
                return false;
            }
        }

        private bool check_config_file () {
            bool return_value = false;
            File file = File.new_for_path (CONFIG_FILE);

            if (file.query_exists ()) {
                return_value = true;
            }

            return return_value;
        }

        private string get_keyword_out_config_file (string keyword, bool dock) {
            // because this it the default set when not defined without '#' in front in config file.
            string return_value = "suspend";
            string line = "";
            if (dock) {
                return_value = "ignore";
            }

            long keyword_indicator = get_keyword_file_indicator (keyword);

            if (keyword_indicator != 0) {
                FileStream stream = FileStream.open (CONFIG_FILE, "r");
                stream.seek (keyword_indicator, FileSeek.SET);
                line = stream.read_line ();
                string[] tmp = line.split ("=");
                return_value = tmp[1];
            }

            return return_value;
        }

        private long get_keyword_file_indicator (string keyword) {
            long return_value = 0;

            FileStream stream = FileStream.open (CONFIG_FILE, "r");
            string line = "";
            while (!stream.eof ()) {
                long tmp = stream.tell ();
                line = stream.read_line ();
                if(line.contains (keyword) && !line.contains ("#"+keyword)) {
                    return_value = tmp;
                    break;
                }
            }

            return return_value;
        }

        private bool set_keyword_action (string keyword, string action) {
            bool succeded = false;
            try {

                FileStream stream_in = FileStream.open (CONFIG_FILE, "r");
                FileStream stream_out = FileStream.open (CONFIG_FILE + "_new", "a");
                string writable = keyword + "=" + action ;

                string line = "";
                while ((line = stream_in.read_line ()) != null) {
                    string[] tmp = line.split ("=");
                    if(tmp[0] == keyword) {
                        stream_out.puts (writable + "\n");
                        succeded = true;
                    } else if (tmp[0] == "#"+keyword) {
                        stream_out.puts (writable + "\n");
                        succeded = true;
                    } else {
                        stream_out.puts (line + "\n");
                    }                    
                }

                stream_out.flush ();
                File file_old = File.new_for_path (CONFIG_FILE);
                File file_new = File.new_for_path (CONFIG_FILE + "_new");
                file_old.delete ();
                file_new.move (file_old, FileCopyFlags.NONE ,null,null);

            } catch (Error e) {
                succeded = false;
            }
            return succeded;
        }
    }
}