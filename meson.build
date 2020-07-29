# Name our project
project('com.github.lainsce.notejot', ['vala', 'c'],
    version: '2.0.0'
)

# Import main lib files
gnome = import('gnome')
i18n = import('i18n')

# Set this for convenience
conf = configuration_data()

asresources = gnome.compile_resources(
    'as-resources', join_paths('data', 'com.github.lainsce.notejot.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

# Get the package data directory under Meson
pkgdatadir = join_paths([ get_option('prefix'),
                          get_option('datadir'),
                          'com.github.lainsce.notejot' ])

conf.set_quoted('PKGDATADIR', pkgdatadir)

# Other configs
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

# Arguments for C
add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DHANDY_USE_UNSTABLE_API'
    ],
    language:'c'
)

cc = meson.get_compiler('c')

# Let's define our executable
executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Services/TaskManager.vala',
    'src/Views/GridView.vala',
    'src/Views/ListView.vala',
    'src/Views/WelcomeView.vala',
    'src/Views/NoteView.vala',
    'src/Widgets/Column.vala',
    'src/Widgets/EditableLabel.vala',
    'src/Widgets/FlowGrid.vala',
    'src/Widgets/Note.vala',
    'src/Widgets/NoteBox.vala',
    'src/Widgets/TextField.vala',
    'src/Styles/light.vala',
    'src/Styles/dark.vala',
    asresources,
    dependencies: [
        dependency('granite'),
        dependency('libhandy-1'),
        dependency('gobject-2.0'),
        dependency('webkit2gtk-4.0'),
        dependency('json-glib-1.0'),
        dependency('gee-0.8'),
        dependency('libhandy-1'),
        dependency('gtk+-3.0')
    ],
    vala_args: [
        meson.source_root() + '/vapi/config.vapi',
        '--vapidir=' + meson.source_root() + '/vapi/',
    ],
    install : true
)

# Add in a post install script
meson.add_install_script('meson/post_install.py', join_paths(get_option('prefix'), get_option('datadir')))

# Add subfolders for Meson to look
subdir('data')
subdir('po')
