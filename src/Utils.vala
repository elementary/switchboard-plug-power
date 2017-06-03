/*
 * Copyright (c) 2017 elementary LLC. (https://launchpad.net/switchboard-plug-power)
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
	public class Utils {
        public enum Action {
            IGNORE,
            POWEROFF,
            LOCK,
            SUSPEND,
            HALT,
            UNKNOWN;

            public static Action from_string (string str) {
	            switch (str) {
	                case "ignore":
	                    return Utils.Action.IGNORE;
	                case "poweroff":
	                    return Utils.Action.POWEROFF;
	                case "lock":
	                    return Utils.Action.LOCK;
	                case "suspend":
	                    return Utils.Action.SUSPEND;
	                case "halt":
	                    return Utils.Action.HALT;
	                default:
	                    return Utils.Action.UNKNOWN;
	            }
            }

            public string to_string () {
                switch (this) {
                    case Action.IGNORE:
                        return "ignore";
                    case Action.POWEROFF:
                        return "poweroff";
                    case Action.LOCK:
                        return "lock";
                    case Action.SUSPEND:
                        return "suspend";
                    case Action.HALT:
                        return "halt";
                    default:
                    	return "unknown";
                }
            }
        }

		private static LogindHelper? instance;
		public static unowned LogindHelper? get_logind_helper () {
			if (instance == null) {
				try {
					instance = Bus.get_proxy_sync (BusType.SYSTEM, LOGIND_HELPER_NAME, LOGIND_HELPER_OBJECT_PATH);
				} catch (Error e) {
					warning (e.message);
				}
			}

			return instance;
		}
	}
}