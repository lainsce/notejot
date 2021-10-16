#!/usr/bin/env python3
import os
import subprocess

install_prefix = os.environ['MESON_INSTALL_PREFIX']
icondir = os.path.join(install_prefix, 'share', 'icons', 'hicolor')
schemadir = os.path.join(install_prefix, 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas…')
    subprocess.call(['glib-compile-schemas', schemadir], shell=False)

    print('Rebuilding desktop icons cache...')
    subprocess.call(['gtk4-update-icon-cache', '-qtf', icondir], shell=False)
