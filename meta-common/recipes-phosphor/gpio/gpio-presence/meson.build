project(
    'gpio-presence',
    'cpp',
    default_options: [
        'warning_level=3',
        'cpp_std=c++23'
    ],
    license: 'Apache-2.0',
    version: '0.1',
    meson_version: '>=1.1.1',
)
cpp = meson.get_compiler('cpp')

add_project_arguments('-Wno-psabi -Wno-unused-variable', language: 'cpp')

systemd = dependency('systemd')
servicedir = systemd.get_pkgconfig_variable('systemdsystemunitdir')

sdbusplus = dependency('sdbusplus')
sdeventplus = dependency('sdeventplus')
phosphor_dbus_interfaces = dependency('phosphor-dbus-interfaces')
phosphor_logging = dependency('phosphor-logging')
gpio = dependency('libgpiodcxx', default_options: ['bindings=cxx'])
nlohmann_json_dep = dependency('nlohmann_json')

executable(
    'gpio-presence',
    'src/gpio_presence.cpp',
    include_directories: include_directories('src'),
    dependencies: [systemd, sdbusplus, sdeventplus, phosphor_dbus_interfaces, phosphor_logging, gpio, nlohmann_json_dep],
)

