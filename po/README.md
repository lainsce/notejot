# How to Translate Notejot
## First Things First

* Clone this repository by opening the terminal in a folder of your choice and typing ```git clone https://github.com/lainsce/notejot```

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
