<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
<policyconfig>
  <vendor>elementary</vendor>
  <vendor_url>http://elementaryos.io/</vendor_url>

  <action id="org.pantheon.switchboard.power.administration">
    <description gettext-domain="@GETTEXT_PACKAGE@">Manage power settings </description>
    <message gettext-domain="@GETTEXT_PACKAGE@">Authentication is required to manage power settings</message>
    <icon_name>preferences-desktop-power</icon_name>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">@PKGDATADIR@/systemd</annotate>
  </action>

</policyconfig>