# Switchboard Power Plug
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard-plug-power.svg)](https://repology.org/metapackage/switchboard-plug-power)
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-power/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-power)

## Building and Installation

You'll need the following dependencies:

* cmake
* gnome-settings-daemon-dev
* libswitchboard-2.0-dev
* libgranite-dev
* libpolkit-gobject-1-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard
