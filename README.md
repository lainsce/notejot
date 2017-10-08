# ![icon](data/icon.png) Notejot
## Stupidly simple sticky notes applet.
[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.lainsce.notejot)

![Screenshot](data/shot.png)

## Donations

Would you like to support the development of this app to new heights? Then:
[Be my backer on Patreon](https://www.patreon.com/lainsce)

## Dependencies

Please make sure you have these dependencies first before building.

```
granite
gtk+-3.0
gtksourceview-3.0
meson
```

## Building

Simply clone this repo, then:

```
$ meson build && cd build
$ meson configure -Dprefix=/usr
$ sudo ninja install
```
