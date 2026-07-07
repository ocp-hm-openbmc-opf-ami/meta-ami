sasl_xoauth2_sources = [
  'client-oauth.c'
]

sasl_xoauth2 = shared_module('xoauth2', sasl_xoauth2_sources,
			   name_prefix : 'sasl-',
			   include_directories: [ include_dir, ],
			   install : true,
			   install_dir: auth_plugin_dir)
clients += sasl_xoauth2
