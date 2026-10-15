project('pldm_oem_hooks', 'cpp',
  version : '1.0',
  default_options : ['buildtype=release', 'default_library=shared', 'cpp_std=c++20']
)

# Find and link phosphor-logging
phosphor_logging_dep = dependency('phosphor-logging', required: true)

# Subdirectory for source files
subdir('src')

# Define the installation directory for the library
install_subdir('include', install_dir: get_option('includedir'))
