all:
	make build
build:
	valac --pkg pantheon power.vala -o power

install:
	mkdir -p /usr/lib/plugs/
	rm /usr/lib/plugs/power -rf
	cp . /usr/lib/plugs/power/ -R

uninstall:
	rm /usr/lib/plugs/power/ -rf
 
clean:
	rm power
 
run:
	switchboard
	
