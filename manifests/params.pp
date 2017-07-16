#
# = Class: pacemaker::params
#
# This module contains defaults for pacemaker modules
#
class pacemaker::params {

  # install package depending on major version
  case $::osfamily {
    default: {}
    /(RedHat|redhat|amazon|Debian|debian|Ubuntu|ubuntu)/: {
      $package_pcs       = 'pcs'
      $package_psmisc    = 'psmisc'
      $package_pacemaker = 'pacemaker'

      $service_pcsd      = 'pcsd'
      $service_corosync  = 'corosync'
      $service_pacemaker = 'pacemaker'

      $hacluster_user    = 'hacluster'
    }
  }

}
