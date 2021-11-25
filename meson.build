project('io.github.lainsce.Notejot', 'vala',
        version: '3.3.3',
  meson_version: '>= 0.59.2'
)

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments([
		'--target-glib=2.40',
	],
	language: 'vala',
)

if get_option('profile') == 'development'
  name_prefix = '(Development) '
  profile = '.Devel'
else
  name_prefix = ''
  profile = ''
endif

app_id = '@0@@1@'.format(meson.project_name(), profile)

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('G_LOG_DOMAIN', '@0@@1@'.format(meson.project_name(), profile))
conf.set_quoted('NAME_PREFIX', name_prefix)
conf.set_quoted('PACKAGE_NAME', meson.project_name())
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('PROFILE', profile)
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('DATADIR', join_paths(get_option('prefix'), get_option('datadir')))
conf.set_quoted('GNOMELOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')


add_project_arguments(
    '-include', 'config.h',
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

asresources = gnome.compile_resources(
    'as-resources', 'data/io.github.lainsce.Notejot.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Models/Note.vala',
    'src/Models/Notebook.vala',
    'src/Repositories/NoteRepository.vala',
    'src/Repositories/NotebookRepository.vala',
    'src/Services/SettingsManager.vala',
    'src/Services/StyleManager.vala',
    'src/Utils/FileUtils.vala',
    'src/Utils/FormatUtils.vala',
    'src/Utils/NoteSorter.vala',
    'src/Utils/ObservableList.vala',
    'src/Utils/ThreadUtils.vala',
    'src/Utils/TimeUtils.vala',
    'src/ViewModels/NoteViewModel.vala',
    'src/ViewModels/NotebookViewModel.vala',
    'src/Views/NoteContentView.vala',
    'src/Views/NoteListView.vala',
    'src/Views/NotebookListView.vala',
    'src/Views/NotebookMoveListView.vala',
    'src/Views/View.vala',
    'src/Widgets/EditNotebookDialog.vala',
    'src/Widgets/NoteRowBadge.vala',
    'src/Widgets/NoteRowContent.vala',
    'src/Widgets/NoteRowPin.vala',
    'src/Widgets/MoveToDialog.vala',
    'src/Widgets/NotebookRowDelete.vala',
    'src/Widgets/NotebookRowEntry.vala',
    'src/Widgets/NoteTheme.vala',
)

dependencies = [
    dependency('gio-2.0'),
    dependency('gtk4'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),
    dependency('libadwaita-1'),
    dependency('gmodule-2.0'),
    dependency('json-glib-1.0'),
    meson.get_compiler('c').find_library('m', required: true)
]

executable(
    meson.project_name(),
    sources,
    asresources,
    dependencies: dependencies,
    vala_args: [meson.project_source_root() + '/src/Config.vapi'],
    install : true
)

subdir('data')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true
)
