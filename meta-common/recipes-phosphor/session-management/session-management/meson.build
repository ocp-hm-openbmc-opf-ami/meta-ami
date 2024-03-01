project(
  'session-management',
  'cpp',
  default_options: [
    'warning_level=3',
    'werror=true',
    'cpp_std=c++23'
  ],
  license: 'Apache-2.0',
  version: '1.0',
  meson_version: '>=1.1.1',
)

deps = [
  dependency('systemd'),
  dependency('sdbusplus'),
  dependency('phosphor-logging'),
]
systemd = dependency('systemd')
install_data(
    ['xyz.openbmc_project.SessionManager.service'],
    install_dir: systemd.get_variable('systemdsystemunitdir')
  )

executable(
  'session-management',
  'session_management.cpp',
  dependencies: deps,
  install: true,
)
