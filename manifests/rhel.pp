# @example
#   include nodripa

class nodripa::rhel(
  $parent_dirs = ['/root/.puppetlabs', '/root/.puppetlabs/bolt',]
){
  yumrepo { 'puppet-tools':
    ensure         => present,
    name           => 'puppet-tools',
    baseurl        => "http://yum.puppet.com/puppet-tools/el/${facts['os']['release']['major']}/\$basearch",
    enabled        => '1',
    gpgcheck       => '0',
    before         => Package['puppet-bolt'],
  }
  package { 'puppet-bolt':
    ensure         => 'installed',
    provider       => yum,
  }
  file {'/tmp/certname-replace.sh':
    ensure         => present,
    source         => ['puppet:///modules/nodripa/certname-replace.sh'],
    mode           => '0744',
    before         => Service['nodripa'],
  }
  if $nodripa::bolt_transport == pcp {
    file { $parent_dirs:
      ensure => directory,
    }
    file {'/tmp/bolt-nodripa.sh':
      ensure         => present,
      source         => ['puppet:///modules/nodripa/bolt-nodripa-pcp.sh'],
      mode           => '0744',
      before         => Service['nodripa'],
    }
    file {'/root/.puppetlabs/bolt/inventory.yaml':
      ensure         => present,
      content        => epp('nodripa/inventory.yaml.epp'),
      mode           => '0644',
      require        => File['/root/.puppetlabs/bolt'],
      before         => Service['nodripa'],
    }
    file {'/root/.puppetlabs/token':    
      ensure         => present,
      content        => $nodripa::access_token,
      mode           => '0644',
      require        => File['/root/.puppetlabs/bolt'],      
      before         => Service['nodripa'],
    }
  }    
  elsif $nodripa::bolt_transport == ssh {
    file {'/tmp/bolt-nodripa.sh':
      ensure         => present,
      content        => epp('nodripa/bolt-nodripa.sh.epp'),
      mode           => '0744',
      before         => Service['nodripa'],
    }
    file { $nodripa::ssh_key:
      ensure         => present,
      content        => $nodripa::private_key,
      mode           => '0600',
    }
  }
  file {'/tmp/pe-version_ssl-clean.sh':
    ensure         => present,
    source         => ['puppet:///modules/nodripa/pe-version_ssl-clean.sh'],
    mode           => '0744',
    before         => Service['nodripa'],
  }
  file { '/etc/systemd/system/nodripa.service':
    ensure         => present,
    source         => ['puppet:///modules/nodripa/nodripa.service'],
    notify         => Service['nodripa'],
  }
  service { 'nodripa':
    ensure         => running,
    enable         => true,
  }
}
