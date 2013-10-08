# == Definition: solr::core
# This definition sets up solr config and data directories for each core
#
# === Parameters
# - The $core to create
#
# === Actions
# - Creates the solr web app directory for the core
# - Copies over the config directory for the file
# - Creates the data directory for the core
#
define solr::core(
  $core_name            = $title,
  $core_conf_ignore     = $solr::params::core_conf_ignore,
  $core_conf_source_uri = $solr::params::core_conf_source_uri,
) {
  include solr::params

  $solr_home  = $solr::params::solr_home

  file { "${solr_home}/${core_name}":
    ensure  => directory,
    owner   => 'jetty',
    group   => 'jetty',
    require => File[$solr_home],
  }

  #Copy its config over
  file { "${solr_home}/${core_name}/conf":
    ensure  => directory,
    source  => $core_conf_source_uri,
    ignore  => $core_conf_ignore,
    recurse => true,
    require => File["${solr_home}/${core_name}"],
  }

  #Finally, create the data directory where solr stores
  #its indexes with proper directory ownership/permissions.
  file { "/var/lib/solr/${core_name}":
    ensure  => directory,
    owner   => 'jetty',
    group   => 'jetty',
    require => File["${solr_home}/${core_name}/conf"],
  }

}
