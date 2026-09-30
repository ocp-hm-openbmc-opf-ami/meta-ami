# Sources for the library
sources = [
  'oemCreateDeviceInventory.cpp',
  'oemCreateFirmwareInventory.cpp',
  'oemCreateComponentName.cpp',
  'oemIsNoneSensorEnabled.cpp',
  'oemExtendPlatformEvents.cpp',
  'oemRegisterCmdHandlers.cpp',
  'oemNamingNumericSensor.cpp',
  'oemGetSensorPollingInterval.cpp',
]

comp = meson.get_compiler('cpp')

# Shared library target
pldm_oem_hooks = shared_library('pldm_oem_hooks',
  sources,
  dependencies: [phosphor_logging_dep],
  include_directories : include_directories('.'),
  install : true,
  version : '1.0.0',          # Library version
  soversion : '1'             # ABI version
)
