[DBus (name = "io.elementary.pantheon.AccountsService")]
interface Power.Greeter.AccountsService : Object {
    [DBus (name = "SleepInactiveACTimeout")]
    public abstract int sleep_inactive_ac_timeout { get; set; }
    [DBus (name = "SleepInactiveACType")]
    public abstract int sleep_inactive_ac_type { get; set; }

    public abstract int sleep_inactive_battery_timeout { get; set; }
    public abstract int sleep_inactive_battery_type { get; set; }
}

[DBus (name = "org.freedesktop.Accounts")]
interface Power.FDO.Accounts : Object {
    public abstract string find_user_by_name (string username) throws GLib.Error;
}
