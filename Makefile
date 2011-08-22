all:
	make build && make clean && make install && make run
build:
	valac --pkg pantheon power.vala -o power

install:
	sudo cp ./* /usr/share/plugs/power/

clean:
	sudo rm /usr/share/plugs/power/*

run:
	switchboard
	
