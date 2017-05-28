# project name
project (com.github.lainsce.notejot)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/com.github.lainsce.notejot")

set (EXEC_NAME "com.github.lainsce.notejot")
set (RELEASE_NAME "Level 1")
set (VERSION "1.0.3")
set (VERSION_INFO "Stable")

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED
    granite
    gtk+-3.0
    gtksourceview-3.0
)

# make sure we have the latest granite
pkg_check_modules(GRANITE0401 QUIET granite>=0.4.0.1)
if (GRANITE0401_FOUND)
    set (GRANITE_OPTIONS --define=HAS_GRANITE_4_1)
endif ()

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# use config to surface app build details
configure_file (${CMAKE_SOURCE_DIR}/cmake/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.26.2" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Application.vala
    src/MainWindow.vala
    src/Widgets/Toolbar.vala
    src/Widgets/SourceView.vala
    src/Constants/Stylesheet.vala
    src/Constants/AppSettings.vala
    src/Utils/FileUtils.vala
    src/Utils/DialogUtils.vala

# tell what libraries to use when compiling
PACKAGES
    granite
    gtk+-3.0
    gtksourceview-3.0

# some extra options
CUSTOM_VAPIS
    vapi/config.vapi

OPTIONS
    ${GRANITE_OPTIONS}
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.lainsce.notejot.desktop DESTINATION ${DATADIR}/applications/)

# install our .appdata.xml file so AppCenter will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.lainsce.notejot.appdata.xml DESTINATION ${DATADIR}/metainfo/)

# Add icons
add_subdirectory (data)

# Translation files
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
