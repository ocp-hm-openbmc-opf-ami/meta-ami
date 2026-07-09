project('mctp-i3c-daemon', 'cpp',
  version: '1.0',
  default_options: ['cpp_std=c++23', 'warning_level=3', 'cpp_args=-Wno-unused-variable'])

inc = include_directories('include')

mctp_dependencies = []

# Add systemd as a dependency
systemd_dep = dependency('libsystemd')

# Add sdbusplus as a dependency
sdbusplus_dep = dependency('sdbusplus')

jsonc_dep = dependency('json-c', required: true)

# Add boost as a dependency
boost_dep = dependency('boost', modules : ['system'])

mctp_dependencies += [systemd_dep, sdbusplus_dep, boost_dep, jsonc_dep]

if get_option('aspeed-soc').enabled()
  add_project_arguments('-DASPEED_SOC', language: ['c', 'cpp'])
endif

if get_option('aspeed-2700-soc').enabled()
  add_project_arguments('-DASPEED_2700_SOC', language: ['c', 'cpp'])
endif

if get_option('nuvoton-soc').enabled()
  add_project_arguments('-DNUVOTON_SOC', language: ['c', 'cpp'])
endif

if get_option('client-socket-interface').enabled()
  add_project_arguments('-DCLIENT_SOCKET_INTERFACE', language: ['c', 'cpp'])
endif

cxx = meson.get_compiler('cpp')
add_project_arguments(
  cxx.get_supported_arguments([
    '-DBOOST_ALL_NO_LIB',
    '-DBOOST_ALLOW_DEPRECATED_HEADERS',
    '-DBOOST_ASIO_DISABLE_THREADS',
    '-DBOOST_ASIO_NO_DEPRECATED',
    '-DBOOST_URL_NO_SOURCE_LOCATION',
    '-DBOOST_SPIRIT_X3_NO_RTTI',
    '-DBOOST_NO_RTTI',                 
    '-DSDBUSPLUS_DISABLE_BOOST_COROUTINES',
  ]),
  language: 'cpp',
)

# Define the executable
executable('mctp-i3c-daemon',
  sources: ['mctp-i3c-main.cpp', 'mctp-netlink.cpp', 'mctp-log.cpp', 'utils.cpp', 'MctpDevice.cpp', 'mctp-ctrl-cmds.cpp', 'mctp-encode.cpp', 'mctp-i3c-client-sock.cpp'],  
  dependencies: mctp_dependencies,
  include_directories: inc,
  install: true)

# Define the executable
executable('mctp-req',
  sources: ['mctp-req.cpp'],
  install: true)


# Define the executable
executable('mctpctrl-cli-sock-test',
  sources: ['mctpctrl-cli-sock-test.cpp'],
  install: true)
