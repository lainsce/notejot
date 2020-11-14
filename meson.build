project('com.github.lainsce.notejot', ['vala', 'c'], version: '2.0.0')
gnome = import('gnome')
i18n = import('i18n')

add_project_arguments([
		'--target-glib=2.40',
	],
	language: 'vala',
)
add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

asresources = gnome.compile_resources(
    'as-resources', join_paths('data', 'com.github.lainsce.notejot.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Services/TaskManager.vala',
    'src/Services/Utils.vala',
    'src/Styles/dark.vala',
    'src/Styles/light.vala',
    'src/Views/GridView.vala',
    'src/Views/ListView.vala',
    'src/Views/TrashView.vala',
    'src/Widgets/EditableLabel.vala',
    'src/Widgets/NoteWindow.vala',
    'src/Widgets/Scrollable.vala',
    'src/Widgets/SettingMenu.vala',
    'src/Widgets/SidebarItem.vala',
    'src/Widgets/TaskBox.vala',
    'src/Widgets/TaskContentView.vala',
    'src/Widgets/TaskLine.vala',
    'src/Widgets/TextField.vala',
    'src/Widgets/TrashedTask.vala',
)

dependencies = [
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),
    dependency('libhandy-1'),
    dependency('granite'),
    dependency('webkit2gtk-4.0'),
    dependency('json-glib-1.0')
]

# Let's define our executable
executable(
    meson.project_name(),
    sources,
    asresources,
    dependencies: dependencies,
    install : true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py', join_paths(get_option('prefix'), get_option('datadir')))