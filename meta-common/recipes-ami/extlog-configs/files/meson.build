project('extlogconfig',
  'cpp',
  version: '1.0',
  meson_version: '>=0.57.0',
  default_options: [
    'werror=true',
    'warning_level=3',
    'cpp_std=c++23',
    'buildtype=debugoptimized',
  ]
)

phosphor_dbus_interfaces = dependency('phosphor-dbus-interfaces')
sdbusplus = dependency('sdbusplus')
sdeventplus = dependency('sdeventplus')
systemd = dependency('systemd')
phosphor_logging_dep = dependency('phosphor-logging')


cpp = meson.get_compiler('cpp')

executable(
  'extlogconfigs',
  'src/main.cpp',
  'include/main.hpp',
  dependencies: [
    sdbusplus,
    sdeventplus,
    phosphor_dbus_interfaces,
    phosphor_logging_dep,
  ],
  link_args: ['-lcrypt', '-lstdc++fs'],
  cpp_args: ['-DBOOST_ALL_NO_LIB', '-DBOOST_SYSTEM_NO_DEPRECATED', '-DBOOST_ERROR_CODE_HEADER_ONLY'],
  install: true,
)
