include (GSettings)

add_schema ("com.github.lainsce.notejot.gschema.xml")
install (FILES com.github.lainsce.notejot.desktop DESTINATION share/applications)
install (FILES com.github.lainsce.notejot.appdata.xml DESTINATION share/metainfo/)
