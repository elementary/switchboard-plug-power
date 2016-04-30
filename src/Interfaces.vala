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
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

namespace Power {

 [DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
    interface PowerSettings : GLib.Object {
#if OLD_GSD
        public abstract uint GetPercentage () throws IOError;
        public abstract uint SetPercentage (uint percentage) throws IOError;
#else
        // use the Brightness property after updateing g-s-d to 3.10 or above
        public abstract int Brightness {get; set; }
#endif
    }

	[DBus (name = "org.freedesktop.UPower.Device")]
	interface UpowerDevice : Object {
		public signal void Changed ();
		public abstract void Refresh () throws IOError;
		public abstract bool Online { owned get; private set; }
		public abstract bool PowerSupply { owned get; private set; }
		public abstract bool IsPresent { owned get; private set; }
	}


	[DBus (name = "org.freedesktop.UPower")]
	interface Upower : Object {
		public signal void Changed ();
		public abstract bool OnBattery { owned get; private set; }
		public abstract bool LowOnBattery { owned get; private set; }
		public abstract ObjectPath[] EnumerateDevices () throws IOError;
	}

	[DBus (name = "org.freedesktop.DBus.Properties")]
	public interface UpowerProperties : Object {
		public abstract Variant Get (string interface, string propname) throws IOError;
		public abstract void Set (string interface, string propname, Variant value) throws IOError;
	}
}
