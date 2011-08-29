all:
	make build
build:
	valac --pkg pantheon power.vala -o power

install:
	rm /usr/lib/plugs/power -rf
	mkdir -p /usr/lib/plugs/power
	cp ./power ./power.ui ./power.plug /usr/lib/plugs/power/
uninstall:
	rm /usr/lib/plugs/power/ -rf
 
clean:
	rm power
 
run:
	switchboard
	
