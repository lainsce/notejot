project (com.github.lainsce.notejot)

cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

set (PKGDATADIR "${DATADIR}/com.github.lainsce.notejot")

set (EXEC_NAME "com.github.lainsce.notejot")
set (RELEASE_NAME "Level 1-1")
set (VERSION "0.1.0")
set (VERSION_INFO "- Added basic functionality.")

find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED
    gtk+-3.0
    gtksourceview-3.0
)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/notejot.vala

PACKAGES
    gtk+-3.0
    gtksourceview-3.0
)

add_executable(${EXEC_NAME} ${VALA_C})

install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.lainsce.notejot.desktop DESTINATION ${DATADIR}/applications/)

install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.lainsce.notejot.appdata.xml DESTINATION ${DATADIR}/metainfo/)
