# How to Translate Notejot

## First Things First

* Fork the repository here on github with the Fork button at the top-right
* Clone this repository by opening the terminal in a folder of your choice and typing `git clone https://github.com/<you_username>/notejot`
* (Optional) Check [Regenerate translations files](https://github.com/lainsce/notejot/tree/translations/po#regenerate-translations-files) section if files haven't been recently updated.

## Basics

* You'll need to know your language's code (ex. en = English).
* Add that code to the LINGUAS file, in a new line, after the last line.
* Translate the .pot file using the PO editor of your choice (I recommend POEdit).
* Save it as <language_code>.po in this folder.

## Not so Basics

* Next, in the folder you've cloned this repo in, open a terminal and type: ```git checkout -b "Translation <language code>```
* Then, type ```git add *```
* Finally, ```git commit -m "Translated your app for <Language Name>" && git push```, follow the instructions in the terminal if need be, then type your github username and password.

And that's it! You've successfully translated Notejot for your language!

## Regenerate translations files
* Initialize the project build by typing `meson _build` (make sure you have [dependencies](https://github.com/lainsce/notejot#dependencies) installed!).
* Compile .pot files, type `meson compile -C _build io.github.lainsce.Notejot-pot` and `meson compile -C _build extra-pot`
* (Optional) Compile .po files instead replacing `-pot` with `-update-po` in the previous commands.

Note: install `apppstream` package in order to generate release strings in `extra.pot`
