# ![icon](data/icon.png) Notejot

## Stupidly simple sticky notes applet

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.lainsce.notejot)

[![Build Status](https://travis-ci.org/lainsce/notejot.svg?branch=master)](https://travis-ci.org/lainsce/notejot)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Screenshot](data/shot.png)

## License

Fonts under the `/data/font` directory are under [License: SIL OFL 1.1](http://scripts.sil.org/OFL), also copied there in full.

## Donations

Would you like to support the development of this app to new heights? Then:

[Be my backer on Patreon](https://www.patreon.com/lainsce)

## Dependencies

Please make sure you have these dependencies first before building.

```bash
granite
gtk+-3.0
gtksourceview-3.0
libjson-glib
libgee-0.8
meson
```

## Building

Simply clone this repo, then:

```bash
meson build && cd build
meson configure -Dprefix=/usr
sudo ninja install
```
