# Class: mesos::install
#
# This class manages Mesos package installation.
#
# Parameters:
# [*ensure*] - 'present' for installing any version of Mesos
#   'latest' or e.g. '0.15' for specific version
#
# Sample Usage: is not meant for standalone usage, class is
# required by 'mesos::master' and 'mesos::slave'
#
class mesos::install(
  $ensure         = 'present'
) {
 
   $version = "0.26.0"
   $package_filename = "mesos_${version}-0.2.145.ubuntu1404_amd64.deb"

   exec { "wget ${package_filename}":
     command => "/usr/bin/wget -q https://s3.amazonaws.com/reddit-packages/any/amd64/${package_filename} -O /tmp/${package_filename}",
     creates => "/tmp/${package_filename}",
     cwd     => '/',
     user    => 'root',
   }

   file { "/tmp/${package_filename}":
     owner   => 'root',
     group   => 'root',
     mode    => '0644',
     require => Exec["wget ${package_filename}"],
   }

   package { "libsvn1":
     ensure => installed
   }

   package { "mesos":
     provider => 'dpkg',
     ensure => present,
     source   => "/tmp/${package_filename}",
     require  => [ Exec["wget ${package_filename}"], Package["libsvn1"] ],
   }

}
