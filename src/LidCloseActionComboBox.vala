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
namespace Power {
    class LidCloseActionComboBox : Gtk.ComboBoxText {

        public Gtk.Label label;
        private CliCommunicator cli_communicator;

        public LidCloseActionComboBox (string label_name, CliCommunicator cli_comm) {
            cli_communicator = cli_comm;
            label = new Gtk.Label (label_name);
            label.halign = Gtk.Align.END;
            ((Gtk.Misc) label).xalign = 1.0f;

            if (cli_communicator.supported) {
                append_text (_("Suspend"));
                append_text (_("Shutdown"));
                append_text (_("Lock"));
                append_text (_("Halt"));
                append_text (_("Do nothing"));
            } else {
                append_text (_("Not supported"));
            }            

            hexpand = true;
            set_current_action ();
            changed.connect (update_action);
        }

        private void update_action () {
            CliCommunicator.Action action = get_action ();
            debug ("action:%s",action.to_string());
            if (label.label.contains ("dock")) {
                cli_communicator.set_action_state(action, true);
            } else {
                cli_communicator.set_action_state (action, false);
            }
            set_current_action ();
        }

        private void set_current_action () {
            if (label.label.contains ("docked")) {
                set_active_item (cli_communicator.lid_close_dock);
            } else {
                set_active_item (cli_communicator.lid_close);
            }
        }

        private CliCommunicator.Action get_action () {
            CliCommunicator.Action action = CliCommunicator.Action.NOT_SUPPORTED;
            debug ("active:%d", active);
            switch (active) {
                case 0:
                    action  = CliCommunicator.Action.SUSPEND;
                    break;
                case 1:
                    action  = CliCommunicator.Action.POWEROFF;
                    break;
                case 2:
                    action  = CliCommunicator.Action.LOCK;
                    break;
                case 3:
                    action  = CliCommunicator.Action.HALT;
                    break;
                case 4:
                    action  = CliCommunicator.Action.IGNORE;
                    break;
                default:
                    break;
            }

            return action;
        }

        private void set_active_item (CliCommunicator.Action action) {
            switch (action) {
                case CliCommunicator.Action.SUSPEND:
                    active = 0;
                    break;
                case CliCommunicator.Action.POWEROFF:
                    active = 1;
                    break;
                case CliCommunicator.Action.LOCK:
                    active = 2;
                    break;
                case CliCommunicator.Action.HALT:
                    active = 3;
                    break;
                case CliCommunicator.Action.IGNORE:
                    active = 4;
                    break;
                case CliCommunicator.Action.NOT_SUPPORTED: // see constructor
                    active = 0;
                    break;
                default:
                    break;
            }
        }
    }
}