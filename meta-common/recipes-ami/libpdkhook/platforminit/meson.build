project(
  'platforminit',
  'cpp',
  default_options: [
    'warning_level=3',
    'werror=true',
    'cpp_std=c++23'
  ],
  meson_version: '>=1.1.1',
)

deps = [
  dependency('systemd'),
  dependency('sdbusplus'),
  dependency('phosphor-logging'),
]

pdkhook_deps = [ declare_dependency (link_args: '-lpdkhook'),]

systemd = dependency('systemd')
install_data(
    ['platforminit.service'],
    install_dir: systemd.get_variable('systemdsystemunitdir')
  )


executable(
  'platforminit',
  'main.cpp',
  dependencies: [deps, pdkhook_deps],
  install: true,
)
