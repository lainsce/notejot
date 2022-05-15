project('io.github.lainsce.Notejot', 'vala',
        version: '3.5.2',
        meson_version: '>= 0.59.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments([
		'--target-glib=2.68',
	],
	language: 'vala',
)

if get_option('development')
  app_id = 'io.github.lainsce.Notejot.Devel'
  name_suffix = ' (Development)'
else
  app_id = 'io.github.lainsce.Notejot'
  name_suffix = ''
endif

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('NAME_SUFFIX', name_suffix)
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', app_id)
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf.set10('DEVELOPMENT', get_option('development'))
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

add_project_arguments(
  '-include', 'config.h',
  '-DGETTEXT_PACKAGE="@0@"'.format(app_id),
  language: 'c'
)

asresources = gnome.compile_resources(
  'as-resources', 'data/io.github.lainsce.Notejot.gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

sources = [
  'src/Application.vala',
  'src/MainWindow.vala',
  'src/Models/Note.vala',
  'src/Models/Notebook.vala',
  'src/Models/Trash.vala',
  'src/Repositories/NoteRepository.vala',
  'src/Repositories/NotebookRepository.vala',
  'src/Repositories/TrashRepository.vala',
  'src/Services/MigrationManager.vala',
  'src/Services/SettingsManager.vala',
  'src/Services/StyleManager.vala',
  'src/Utils/FileUtils.vala',
  'src/Utils/FormatUtils.vala',
  'src/Utils/MiscUtils.vala',
  'src/Utils/NoteSorter.vala',
  'src/Utils/ObservableList.vala',
  'src/Utils/ThreadUtils.vala',
  'src/Utils/TimeUtils.vala',
  'src/ViewModels/NoteViewModel.vala',
  'src/ViewModels/NotebookViewModel.vala',
  'src/ViewModels/TrashViewModel.vala',
  'src/Views/NoteContentView.vala',
  'src/Views/NoteGridView.vala',
  'src/Views/NoteListView.vala',
  'src/Views/NotebookListView.vala',
  'src/Views/NotebookMainListView.vala',
  'src/Views/NotebookMoveListView.vala',
  'src/Views/TrashContentView.vala',
  'src/Views/TrashListView.vala',
  'src/Views/View.vala',
  'src/Widgets/EditNotebookDialog.vala',
  'src/Widgets/NoteGridRowContent.vala',
  'src/Widgets/NoteRowContent.vala',
  'src/Widgets/MoveToDialog.vala',
  'src/Widgets/NotebookRowContent.vala',
  'src/Widgets/NoteTheme.vala',
  'src/Widgets/NotePicture.vala',
  'src/Widgets/TrashRowContent.vala',
]

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
