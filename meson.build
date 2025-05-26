project(
  'io.github.lainsce.Notejot',
  'vala',
  version: '3.6.0',
  meson_version: '>= 0.60.0',
)

gnome = import('gnome')
i18n = import('i18n')

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

add_project_arguments(
  '-include', 'config.h',
  '-DGETTEXT_PACKAGE="@0@"'.format(app_id),
  '-w',
  language: 'c',
)
add_project_arguments(
  [
    '--target-glib=2.68',
    '--gresourcesdir', meson.current_build_dir() / 'data',
  ],
  language: 'vala',
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
  'src/Views/NoteListView.vala',
  'src/Views/NotebookListView.vala',
  'src/Views/NotebookMainListView.vala',
  'src/Views/NotebookMoveListView.vala',
  'src/Views/TrashContentView.vala',
  'src/Views/TrashListView.vala',
  'src/Views/View.vala',
  'src/Widgets/EditNotebookDialog.vala',
  'src/Widgets/MainMenu.vala',
  'src/Widgets/NotebookMainRowContent.vala',
  'src/Widgets/NoteRowContent.vala',
  'src/Widgets/MoveToDialog.vala',
  'src/Widgets/NotebookRowContent.vala',
  'src/Widgets/NoteTheme.vala',
  'src/Widgets/TrashRowContent.vala',
]

dependencies = [
  dependency('gio-2.0'),
  dependency('gtk4'),
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gee-0.8'),
  dependency('libhelium-1'),
  dependency('libbismuth-1'),
  dependency('gmodule-2.0'),
  dependency('json-glib-1.0'),
  meson.get_compiler('c').find_library('m', required: true),
]

subdir('data')
subdir('po')

executable(
  meson.project_name(),
  asresources,
  sources: sources,
  vala_args: [
    meson.current_source_dir() + '/src/' + '/Config.vapi',
  ],
  dependencies: dependencies,
  install: true,
)

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
