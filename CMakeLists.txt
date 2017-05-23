project (com.github.lainsce.notejot)

cmake_minimum_required (VERSION 2.6)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/com.github.lainsce.notejot")
set (EXEC_NAME "com.github.lainsce.notejot")
set (RELEASE_NAME "Level 1-4")
set (VERSION "0.1.4")
set (VERSION_INFO "Stable")
set (DOLLAR "$")

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED
    granite
    gtk+-3.0
    gtksourceview-3.0
)

pkg_check_modules(GRANITE0401 QUIET granite>=0.4.0.1)
if (GRANITE0401_FOUND)
    set (GRANITE_OPTIONS --define=HAS_GRANITE_4_1)
endif ()

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

add_subdirectory (src)
add_subdirectory (data)
