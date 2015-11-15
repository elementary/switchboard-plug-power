
namespace Power {
    public static Polkit.Permission? permission = null;

    public static Polkit.Permission? get_permission () {
        if (permission != null) {
            return permission;
        }

        try {
            permission = new Polkit.Permission.sync ("org.pantheon.switchboard.power.administration", Polkit.UnixProcess.new (Posix.getpid ()));
            return permission;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
    }
}