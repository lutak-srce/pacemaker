#
# = Class: pacemaker
#
# This class manages Corosync/Pacemaker cluster
#
class pacemaker (
  $ensure                   = 'present',
  $version                  = undef,
  $package_pcs              = $::pacemaker::params::package_pcs,
  $package_pacemaker        = $::pacemaker::params::package_pacemaker,
  $service_ensure_pcsd      = 'running',
  $service_ensure_corosync  = undef,
  $service_ensure_pacemaker = undef,
  $service_enable_pcsd      = true,
  $service_enable_corosync  = false,
  $service_enable_pacemaker = false,
  $service_name_pcsd        = $::pacemaker::params::service_pcsd,
  $service_name_corosync    = $::pacemaker::params::service_corosync,
  $service_name_pacemaker   = $::pacemaker::params::service_pacemaker,
  $hacluster_user           = $::pacemaker::params::hacluster_user,
  $hacluster_passwd         = 'hacluster',
  $hacluster_hash           = 'sha-512',
  $hacluster_salt           = 'PaAxZ0Lc',
  $cluster_members          = [],
  $cluster_name             = 'cluname',
  $cib_source               = 'UNDEF',
  $file_mode                = '0644',
  $file_owner               = 'root',
  $file_group               = 'root',
  $dependency_class         = 'pacemaker::dependency',
  $my_class                 = undef,
  $noops                    = undef,
) inherits pacemaker::params {

  ### Input parameters validation
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent')
  validate_string($version)
  validate_string($package_pcs)
  validate_string($package_pacemaker)
  validate_re($hacluster_hash, ['md5','sha-256','sha-512'], 'Valid values are: md5, sha-256, sha-512')
  validate_string($hacluster_salt)
  validate_array($cluster_members)
  $cluster_members_flat = join($cluster_members, ' ')
  validate_string($cluster_members_flat)

  ### Internal variables (that map class parameters)
  if $ensure == 'present' {
    $package_ensure = $version ? {
      ''      => 'present',
      default => $version,
    }
    $file_ensure = present
    $user_ensure = present
  } else {
    $package_ensure = absent
    $file_ensure    = absent
    $user_ensure    = absent
  }

  ### Extra classes
  if $dependency_class { include $dependency_class }
  if $my_class         { include $my_class         }

  ### Resources
  Package {
    ensure => $package_ensure,
    noop   => $noops,
  }

  package { 'pcs':       name => $package_pcs }
  package { 'pacemaker': name => $package_pacemaker }

  # set defaults for file resource in this scope.
  File {
    ensure  => $file_ensure,
    owner   => $file_owner,
    group   => $file_group,
    mode    => $file_mode,
    noop    => $noops,
  }

  service { 'pcsd':
    ensure  => $service_ensure_pcsd,
    enable  => $service_enable_pcsd,
    name    => $service_name_pcsd,
    require => Package['pcs'],
  }

  user { 'hacluster':
    ensure   => $user_ensure,
    name     => $hacluster_user,
    password => pw_hash($hacluster_passwd,$hacluster_hash,$hacluster_salt),
    require  => Package['pacemaker'],
  }

  exec { 'pcs_cluster_auth':
    command => "/sbin/pcs cluster auth -u ${hacluster_user} -p ${hacluster_passwd} ${cluster_members_flat}",
    creates => '/var/lib/pcsd/pcs_users.conf',
    require => [
      User['hacluster'], 
      Service['pcsd'], 
    ],
  }

  exec { 'pcs_cluster_setup':
    command => "/sbin/pcs cluster setup --name ${cluster_name} ${cluster_members_flat}",
    creates => '/var/lib/pcsd/pcs_settings.conf',
    require => Exec['pcs_cluster_auth'],
  }

  service { 'corosync':
    ensure  => $service_ensure_corosync,
    enable  => $service_enable_corosync,
    name    => $service_name_corosync,
    require => Exec['pcs_cluster_auth'],
  }

  service { 'pacemaker':
    ensure  => $service_ensure_pacemaker,
    enable  => $service_enable_pacemaker,
    name    => $service_name_pacemaker,
    require => Service['corosync'],
  }

  # Manage cib.xml if specified
  if ( $cib_source != 'UNDEF' ) {

    file { '/var/lib/pacemaker/cib_puppet.xml':
      source  => $cib_source,
      require => Service['pacemaker'],
#     notify  => Exec['pcs_cluster_cibpush'],
    }

#    exec { 'pcs_cluster_cibpush':
#      command   => '/usr/bin/xmllint /var/lib/pacemaker/cib_puppet.xml && /usr/sbin/pcs cluster cib-push /var/lib/pacemaker/cib_puppet.xml',
#      onlyif    => '/usr/bin/diff /var/lib/pacemaker/cib_puppet.xml /var/lib/pacemaker/cib/cib.xml | /bin/egrep "<cluster.*config_version=" > /dev/null',
#      subscribe => File['/etc/cluster.conf'],
#      require   => [ Class['rhcs::ricci'], Service['cman'], ],
#    }
  }

}
# vi:syntax=puppet:filetype=puppet:ts=4:et:nowrap:
