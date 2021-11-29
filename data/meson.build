install_data(
  meson.project_name() + '.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

msgfmt = find_program('msgfmt')
podir = join_paths(meson.source_root(), 'po')
desktop_conf = configuration_data()
desktop_conf.set('icon', app_id)
desktop_file = custom_target('desktop-file',
  input: configure_file(
    input: meson.project_name() + '.desktop.in',
    output: '@BASENAME@' + '.in',
    configuration: desktop_conf
  ),
  output: '@0@.desktop'.format(app_id),
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications'),
  command: [msgfmt, '--desktop',
    '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@',
    '--keyword=X-GNOME-FullName', '--keyword=X-Geoclue-Reason',
    '--keyword=Name', '--keyword=GenericName', '--keyword=Comment', '--keyword=Keywords'
  ]
)
# Validate Desktop file
desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

i18n.merge_file(
  input: meson.project_name() + '.metainfo.xml.in',
  output: meson.project_name() + '.metainfo.xml',
  po_dir: podir,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

subdir('icons')
