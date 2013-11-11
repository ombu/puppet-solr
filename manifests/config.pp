# == Class: solr::config
# This class sets up solr install
#
# === Parameters
# - The $cores to create
#
# === Actions
# - Copies a new jetty default file
# - Creates solr home directory
# - Downloads solr 4.4.0, extracts war and copies logging jars
# - Creates solr data directory
# - Creates solr config file with cores specified
# - Links solr home directory to jetty webapps directory
#
class solr::config(
  $cores                         = $solr::params::cores,
  $core_conf_source_uri_template = $solr::params::core_conf_source_uri_template,
  $core_conf_ignore              = $solr::params::core_conf_ignore,
  $core_conf_example_dir         = $solr::params::core_conf_example_dir,
  $jetty_home                    = $solr::params::jetty_home,
  $solr_home                     = $solr::params::solr_home,
  $solr_version                  = $solr::params::solr_version,
  $filename_template             = $solr::params::filename_template,
  $archive_template              = $solr::params::archive_template,
  $download_url_template         = $solr::params::download_url_template
) {


  #Copy the jetty config file
  file { '/etc/default/jetty':
    ensure  => file,
    source  => 'puppet:///modules/solr/jetty-default',
    require => Package['jetty'],
  }

  file { $solr_home:
    ensure  => directory,
    owner   => 'jetty',
    group   => 'jetty',
    require => Package['jetty'],
  }

  $filename = inline_template($filename_template)
  $archive = inline_template($archive_template)
  $download_url = inline_template($download_url_template)

  # download only if WEB-INF is not present and tgz file is not in /tmp:
  exec { 'solr-download':
    path      =>  ['/usr/bin', '/usr/sbin', '/bin'],
    command => "wget ${download_url}",
    cwd     => '/tmp',
    creates => "/tmp/${archive}",
    onlyif  => "test ! -d ${solr_home}/WEB-INF && test ! -f /tmp/${archive}",
    timeout => 0,
    require => File[$solr_home],
  }

  exec { 'extract-solr':
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
    command => "tar xzvf ${archive}",
    cwd     => '/tmp',
    onlyif  => "test -f /tmp/${archive} && test ! -d /tmp/${filename}",
    require => Exec['solr-download'],
  }

  # have to copy logging jars separately from solr 4.3 onwards
  exec { 'copy-solr':
    path      =>  ['/usr/bin', '/usr/sbin', '/bin'],
    #command   =>  "jar xvf /tmp/${filename}/dist/solr-${solr_version}.war",
    command  =>  "jar xvf /tmp/${filename}/dist/solr-${solr_version}.war && cp /tmp/${filename}/example/lib/ext/*.jar WEB-INF/lib",
    cwd       =>  $solr_home,
    onlyif    =>  "test ! -d ${solr_home}/WEB-INF",
    require   =>  Exec['extract-solr'],
  }

  exec { 'cache-solr-core-conf':
    path      =>  ['/usr/bin', '/usr/sbin', '/bin'],
    command   =>  "mkdir -p core-conf-cache/${solr_version}; cp -R /tmp/${filename}/${core_conf_example_dir} core-conf-cache/${solr_version}", #; cp /tmp/${filename}/example/lib/ext/*.jar WEB-INF/lib",
    cwd       =>  $solr_home,
    creates   =>  "${solr_home}/core-conf-cache/${solr_version}/conf",
    require   =>  Exec['copy-solr'],
  }

  file { '/var/lib/solr':
    ensure    => directory,
    owner     => 'jetty',
    group     => 'jetty',
    mode      => '0700',
    require   => Package['jetty'],
  }

  file { "${solr_home}/solr.xml":
    ensure    => 'file',
    owner     => 'jetty',
    group     => 'jetty',
    content   => template('solr/solr.xml.erb'),
    require   => File['/etc/default/jetty'],
  }

  file { "${jetty_home}/webapps/solr":
    ensure    => 'link',
    target    => $solr_home,
    require   => File["${solr_home}/solr.xml"],
  }

  if $cores {
    $core_conf_source_uri = inline_template($core_conf_source_uri_template)
    solr::core { $cores:
      core_conf_ignore     => $core_conf_ignore,
      core_conf_source_uri => $core_conf_source_uri,
      require              => [File["${jetty_home}/webapps/solr"], Exec['cache-solr-core-conf']],
    }
  }
}

