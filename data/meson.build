conf = configuration_data()
conf.set('app_id', app_id)

desktop_conf = configure_file(
  input: meson.project_name() + '.desktop.in',
  output: '@0@.desktop.in'.format(app_id),
  configuration: conf
)

desktop_file = i18n.merge_file(
  input: desktop_conf,
  output: '@0@.desktop'.format(app_id),
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# Validate Desktop file
desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test('validate-desktop', desktop_file_validate,
    args: [desktop_file]
  )
endif

appstream_conf = configure_file(
  input: meson.project_name() + '.metainfo.xml.in',
  output: '@0@.metainfo.xml.in'.format(app_id),
  configuration: conf
)

appstream_file = i18n.merge_file(
  input: appstream_conf,
  output: '@0@.metainfo.xml'.format(app_id),
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

#Validate Appstream file
appstream_file_validate = find_program('appstream-util', required: false)
if appstream_file_validate.found()
  test('validate-appstream', appstream_file_validate,
    args: ['validate', '--nonet', appstream_file]
  )
endif

install_data(
  meson.project_name() + '.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

subdir('icons')
