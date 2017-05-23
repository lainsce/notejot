find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26.2" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C ${EXEC_NAME}
    Application.vala
    AppSettings.vala
    MainWindow.vala
PACKAGES
    granite
    gtk+-3.0
    gtksourceview-3.0
OPTIONS
    ${GRANITE_OPTIONS}
)

add_executable (${EXEC_NAME} ${VALA_C})
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
