namespace PowerPlug {

    public class BatteryView : Gtk.Grid
    {
        Gtk.CellRendererText cell;
            
        public BatteryView ()
        {
            var grid = new Gtk.Grid ();
         
            var slp_label = new Gtk.Label (_("Put the computer to sleep when inactive:"));
            grid.attach (slp_label, 0, 0, 1, 1);
            
            var slp_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL,new Gtk.Adjustment(1800, 0, 3600, 300, 5, 0));
            slp_scale.set_draw_value (false);
            slp_scale.add_mark (300, Gtk.PositionType.BOTTOM, _("5 Minutes");
            slp_scale.add_mark (600, Gtk.PositionType.BOTTOM, _("10 Minutes");
            slp_scale.add_mark (1800, Gtk.PositionType.BOTTOM, _("30 Minutes");
            slp_scale.add_mark (300, Gtk.PositionType.RIGHT, _("1 Hour");
            slp_scale.set_hexpand (true);
            grid.attach (slp_scale, 1, 0, 1, 4);
            
            var lid_closed_label = new Gtk.Label (_("When the lid is closed:"));
            lid_closed_label.halign = Gtk.Align.END;
            grid.attach (lid_closed_label, 0, 4, 1, 1);
            
            lid_closed_pow = new Gtk.ComboBox.with_model (liststore_lid);
		    cell = new Gtk.CellRendererText();
		    lid_closed_pow.pack_start( cell, false );
		    lid_closed_pow.set_attributes( cell, "text", 0 );
		    grid.attach (lid_closed_pow, 1, 4, 1, 1);
		    
		    var pow_crit_label = new Gtk.Label (_("When power is critically low:"));
		    pow_crit_label.halign = Gtk.Align.END;
		    grid.attach (pow_crit_label, 0, 5, 1, 1);
		
		    pow_crit = new Gtk.ComboBox.with_model (liststore_critical);
		    cell = new Gtk.CellRendererText();
		    pow_crit.pack_start( cell, false );
		    pow_crit.set_attributes( cell, "text", 0 );
            grid.attach (pow_crit, 1, 5, 1, 1);
            
            this.attach (grid, 0, 0, 1, 1);    
        }    
    
    }

}
