<img align="left" style="vertical-align: middle" width="128" height="128" src="data/icons/io.github.lainsce.Notejot.svg">

# Notejot

A very simple notes application for any type of short term notes or ideas.

###

[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Light screenshot](data/shot.png#gh-light-mode-only)
![Dark screenshot](data/shot-dark.png#gh-dark-mode-only)

<p align="center"><a href='https://flathub.org/apps/details/io.github.lainsce.Notejot'><img width='240' alt='Download on Flathub' src='https://flathub.org/assets/badges/flathub-badge-en.png'/></a></p>

## 💝 Donations 

Would you like to support the development of this app to new heights?
Then become a GitHub Sponsor or check my Patreon, buttons in the sidebar.

## 🛠️ Dependencies

Please make sure you have these dependencies first before building.

```bash
gtk4
libjson-glib
libgee-0.8
libadwaita-1
meson
vala
```

## 🏗️ Building

Simply clone this repo, then:

```bash
meson _build --prefix=/usr && cd _build
sudo ninja install
```

## 🗂️ Notes Storage

Notes are stored in `~/.var/app/io.github.lainsce.Notejot/`

## 🔄 Migrating Old Notejot Data

On first launch, Notejot will automatically import your notes from older versions.

## 🔄 Migration Details

- Note colors are saved as the first line of each note.
- Old modification times are preserved as note timestamps.
- Trashed notes remain trashed after migration.
- Notebooks are converted to tags.

After migration:

- A `.notejot_migrated` flag file is created.
- Old files are renamed to `*_migrated.json` for reference and are no longer used.

Migration happens automatically on first launch and keeps your data safe and compatible with the new version.
