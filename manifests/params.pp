# == Class: solr::params
# This class sets up some required parameters
#
# === Actions
# - Specifies jetty and solr home directories
# - Specifies the default core
#
class solr::params {

  $cores                         = ['default']
  $core_conf_source_uri_template = "file://<%= scope.lookupvar('solr::solr_home') -%>/core-conf-cache/<%= scope.lookupvar('solr::solr_version') -%>/conf"
  $core_conf_ignore              = ''
  $core_conf_example_dir         = 'example/solr/collection1/conf'

  $solr_version                  = '4.2.0'

  $solr_home                     = '/usr/share/solr'
  $jetty_home                    = '/usr/share/jetty'

  $filename_template             = 'solr-<%= @solr_version -%>'
  $archive_template              = '<%= @filename -%>.tgz'
  $download_url_template         = 'http://archive.apache.org/dist/lucene/solr/<%= @solr_version -%>/<%= @archive %>'

}

