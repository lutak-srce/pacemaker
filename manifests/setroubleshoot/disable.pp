class selinux::setroubleshoot::disable {
  case $::operatingsystem {
    default: {}
    centos: { include selinux::setroubleshoot::disable::centos }
  }
}
