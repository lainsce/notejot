project(
  'io.github.lainsce.Notejot',
  'vala',
  version: '4.0.0',
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

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(app_id),
  '-w',
  language: 'c',
)
add_project_arguments(
  '--gresourcesdir', meson.current_build_dir() / 'data',
  language: 'vala',
)

sources = [
  'src/Application.vala',
  'src/models/DataManager.vala',
  'src/models/DataModels.vala',
  'src/dialogs/AddTagDialog.vala',
  'src/services/JsonObject.vala',
  'src/services/MapStyle.vala',
  'src/services/ReminderService.vala',
  'src/settings/SettingsManager.vala',
  'src/settings/SettingsWindow.vala',
  'src/views/DeletedEmptyStateView.vala',
  'src/views/EmptyStateView.vala',
  'src/views/EntriesView.vala',
  'src/views/EntryEditorView.vala',
  'src/views/InsightsView.vala',
  'src/views/PlacesView.vala',
  'src/views/Sidebar.vala',
  'src/widgets/WelcomeScreen.vala',
  'src/widgets/TagRow.vala',
  'src/Window.vala',
]

dependencies = [
  dependency('gtk4'),
  dependency('gee-0.8'),
  dependency('libhelium-1'),
  dependency('json-glib-1.0'),
  dependency('libsoup-3.0'),
  dependency('geocode-glib-2.0'),
  dependency('shumate-1.0', version: '>= 1.0.1'),
  meson.get_compiler('c').find_library('m', required: true),
]

subdir('data')
subdir('po')

executable(
  meson.project_name(),
  asresources,
  sources: sources,
  dependencies: dependencies,
  install: true,
)

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
