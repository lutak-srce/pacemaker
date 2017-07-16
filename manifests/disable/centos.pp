class selinux::disable::centos {
  service{'restorecond':
#   ensure => stopped,
    enable => false,
  }
  service{'mcstrans':
#   ensure => stopped,
    enable => false,
  }
  exec{'disable_selinux_sysconfig':
    command => 'sed -i "s@^\(SELINUX=\).*@\1disabled@" /etc/sysconfig/selinux && sed -i "s@^\(SELINUX=\).*@\1disabled@" /etc/selinux/config',
    unless  => 'grep -q "SELINUX=disabled" /etc/selinux/config && grep -q "SELINUX=disabled" /etc/sysconfig/selinux',
  }
}
