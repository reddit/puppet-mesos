Mesos Puppet Module
===================

*COMPATIBILITY NOTE:* current version (0.6.x) requires
``puppetlabs-apt >= 2.1.0`` which has significantly refactored API
(doesn't matter if you don't wanna use Mesosphere APT repo).

For installing master

.. code:: puppet

    class{'mesos::master':
      zookeeper  => 'zk://192.168.1.1:2181,192.168.1.2:2181,192.168.1.3:2181/mesos',
      work_dir => '/var/lib/mesos',
      options => {
        quorum   => 2
      }
    }

example slave configuration:

.. code:: puppet

    class{'mesos::slave':
      zookeeper  => 'zk://192.168.1.1:2181,192.168.1.2:2181,192.168.1.3:2181/mesos',
      listen_address => $::ipaddress,
      attributes => {
        'env' => 'production',
      },
      resources => {
        'ports' => '[2000-65535]'
      }
    }

for using Hiera and other options see below.

Shared parameters
-----------------

Parameters:

-  ``zookeeper`` - ZooKeeper URL which is used for slaves connecting to
   the master and also for leader election, e.g.:

   -  single ZooKeeper: ``zk://127.0.0.1:2181/mesos`` (which isn't fault
      tolerant)

      -  multiple ZooKeepers:
         ``zk://192.168.1.1:2181,192.168.1.2:2181,192.168.1.3:2181/mesos``
         (usually 3 or 5 ZooKeepers should be enough)
      -  ZooKeeper URL will be stored in ``/etc/mesos/zk``,
         ``/etc/default/mesos-master`` and/or
         ``/etc/default/mesos-slave``

-  ``conf_dir`` - directory with simple configuration files containing
   master/slave parameters (name of the file is a key, contents its
   value) - this directory will be completely managed by Puppet
-  ``env_var`` - shared master/slave execution environment variables
   (see example under slave)
-  ``version`` - install specific version of Mesos
-  ``manage_python`` - Control whether mesos module should install
   python
-  ``manage_zk_file`` - Control whether module manages /etc/mesos/zk
   (default: true)
-  ``manage_service`` - Whether Puppet should ensure service state
   (applies to ``mesos-master`` and ``mesos-slave``) (default: true)

Master
~~~~~~

Should be as simple as this, on master node:

``puppet class{'mesos::master': }`` optionally you can specify some
parameters or it is possible to configure Mesos via Hiera (see below).

.. code:: puppet

    class{'mesos::master':
      master_port => 5050,
      work_dir => '/var/lib/mesos',
      options => {
        quorum   => 4
      }
    }

For slave you have to specify either ``master``

.. code:: puppet

    class{'mesos::slave':
      master => '192.168.1.1'
    }

or ``zookeeper`` node(s) to connect:

.. code:: puppet

    class{'mesos::slave':
      zookeeper => 'zk://192.168.1.1:2181,192.168.1.2:2181,192.168.1.3:2181/mesos'
    }

-  ``conf_dir`` default value is ``/etc/mesos-master`` (this directory
   will be purged by Puppet!)

   -  for list of supported options see ``mesos-master --help``

-  ``env_var`` - master's execution environment variables (see example
   under slave)

listen address
^^^^^^^^^^^^^^

If you want to change the IP address Mesos is binding to, you can either
provide a Puppet Fact:

.. code:: puppet

    class{'mesos::master':
      listen_address => $::ipaddress_eth0
    }

or directly use some IP address:

.. code:: puppet

    class{'mesos::master':
      listen_address => '192.168.1.1'
    }

By default no IP address is set, which means that Mesos will use IP to
which translates ``hostname -f`` (you can influence bind address simply
in ``/etc/hosts``).

Slave
~~~~~

-  ``enable`` - install Mesos slave service (default: ``true``)
-  ``port`` - slave's port for incoming connections (default: ``5051``)
-  ``master``- ip address of Mesos master (default: ``localhost``)
-  ``master_port`` - Mesos master's port (default: ``5050``)
-  ``work_dir`` - directory for storing task's temporary files (default:
   ``/tmp/mesos``)
-  ``env_var`` - slave's execution environment variables - a Hash, if
   you are using Java, you might need e.g.:

.. code:: puppet

    class{'mesos::slave':
      master  => '192.168.1.1',
      env_var => {
        'JAVA_HOME' => '/usr/bin/java'
      }
    }

in a similar manner you can specify cgroups isolation:

.. code:: puppet

    class{'mesos::slave':
      zookeeper  => 'zk://192.168.1.1:2181/mesos',
      isolation  => 'cgroups/cpu,cgroups/mem',
      cgroups    => {
        'hierarchy' => '/sys/fs/cgroup',
        'root'      => 'mesos',
      }
    }

-  ``conf_dir`` default value is ``/etc/mesos-slave`` (this directory
   will be purged by Puppet!) - for list of supported options see
   ``mesos-slave --help``

File based configuration
------------------------

As Mesos configuration flags changes with each version we don't provide
directly a named parameter for each flag. ``mesos::property`` allows to
create a parameter file or remove the file when ``value`` is left empty.
e.g. configure value in ``/etc/mesos/hostname``:

.. code:: puppet

    ::mesos::property { 'hostname':
      value => 'mesos.hostname.com',
      dir   => '/etc/mesos'
    }

Remove this file simply set value to undef:

.. code:: puppet

    ::mesos::property { 'hostname':
      value => undef,
      dir   => '/etc/mesos'
    }

This is equivalent approach to

.. code:: puppet

    class{'mesos::slave':
      options => {
        'hostname' => 'mesos.hostname.com'
      }
    }

which will create a file ``/etc/mesos-slave/hostname`` with content
``mesos.hostname.com`` (where ``/etc/mesos-slave`` is a slave's
``$conf_dir``).

Yet another option would be to pass this value via Hiera (see the
section below).

Boolean flags
~~~~~~~~~~~~~

Current Mesos packages recognizes boolean flags like ``--[no-]quiet``
via files named as ``/etc/mesos-slave/?quiet`` for ``--quiet`` (true)
and ``/etc/mesos-slave/?no-quiet`` for false value.

.. code:: puppet

    class{'mesos::slave':
      options => {
        'quiet' => true
      }
    }

*since 0.4.1*

Hiera support
-------------

All configuration could be handled by hiera.

Either specify one master

.. code:: yaml

    mesos::master      : '192.168.1.1'

or `Zookeeper <http://zookeeper.apache.org/>`__ could be use for a
fault-tolerant setup (multiple instances of zookeeper are separated by
comma):

.. code:: yaml

    mesos::zookeeper   : 'zk://192.168.1.1:2181/mesos'

Some parameters are shared between master and slave nodes:

.. code:: yaml

    mesos::master_port : 5050
    mesos::log_dir     : '/var/log/mesos'
    mesos::conf_dir    : '/etc/mesos'
    mesos::owner       : 'mesos'
    mesos::group       : 'mesos'

Other are master specific:

.. code:: yaml

    mesos::master::cluster     : 'my_mesos_cluster'
    mesos::master::whitelist   : '*'

or slave specific:

.. code:: yaml

    mesos:slave::env_var:
      JAVA_HOME: '/usr/bin/java'

Mesos service reads configuration either from ENV variables or from
configuration files wich are stored in ``/etc/mesos-slave`` resp.
``/etc/mesos-master``. Hash passed via ``options`` will be converted to
config files. Most of the options is possible to configure this way:

.. code:: yaml

    mesos::master::options:
      webui_dir: '/usr/local/share/mesos/webui'
      quorum: '4'

you can also use facts from Puppet:

::

    mesos::master::options:
      hostname: "%{::fqdn}"

cgroups with Hiera:

.. code:: yaml

    mesos::slave::isolation: 'cgroups/cpu,cgroups/mem'
    mesos::slave::cgroups:
      hierarchy: '/sys/fs/cgroup'

Limit resources used by Mesos slave:

.. code:: yaml

    mesos::slave::resources:
      cpus: '10'

Python installation
~~~~~~~~~~~~~~~~~~~

Python is required for Mesos Web UI and for CLI as well. Installing
Python with Mesos should be responsibility of binary packages (Mesos
could be build without UI), therefore this behaviour is not enabled by
default.

You can enable this feature with following:

.. code:: puppet

    class{'mesos':
      manage_python => true
    }

or change Python package name, to match your needs:

.. code:: puppet

    class{'mesos':
      manage_python => true,
      python_package => 'python-dev'
    }

Software repository
~~~~~~~~~~~~~~~~~~~

Software repositories could be enabled by defining a source:

.. code:: yaml

    mesos::repo: 'mesosphere'

or in Puppet code:

.. code:: puppet

    class{'mesos':
      repo => 'mesosphere'
    }

by default this feature is disabled and right we support
`mesosphere.io <http://mesosphere.io>`__ repositories for:

-  Debian/Ubuntu
-  RedHat

Feel free to send PR for other distributions/package sources.

Overriding service providers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Some Mesos packages does not respect conventions on given OS for
starting services. For both ``mesos::master`` and ``mesos::slave`` you
can specify mechanism which will be used for starting services.

.. code:: puppet

    class{'mesos::master':
      force_provider => 'upstart'
    }

If you want to create the service resource yourself, set
``force_provider`` to ``none``.

Some reasonable values are:

-  ``init``
-  ``upstart`` - e.g. Ubuntu
-  ``systemd``
-  ``runit``
-  ``none`` - service won't be installed

Packages
~~~~~~~~

You can build package by yourself and upload package to your software
repository. Or use packages from mesosphere.io:

-  Debian/Ubuntu

   -  `mesos deb
      packaging <https://github.com/deric/mesos-deb-packaging>`__
   -  `mesosphere packages <http://mesosphere.io/downloads/>`__

-  RedHat/CentOS

   -  `mesosphere packages <http://mesosphere.io/downloads/>`__

Requirements
------------

-  Puppet > 3.0 and < 5.0

Dependencies
------------

-  `stdlib <https://forge.puppetlabs.com/puppetlabs/stdlib>`__ version
   ``>= 4.2.0`` - we need function ``is_bool``
-  `apt <https://github.com/puppetlabs/puppetlabs-apt>`__ version
   ``>= 2.1.0`` is required for Debian servers (since puppet-mesos 0.6)

Installation
------------

Preferred installation is via
`puppet-librarian <https://github.com/rodjek/librarian-puppet>`__ just
add to ``Puppetfile``:

.. code:: ruby

    mod 'deric/mesos', '>= 0.6.0'

for latest version from git:

.. code:: ruby

    mod 'deric/mesos', :git => 'git://github.com/deric/puppet-mesos.git'

Links
-----

For more information see `Mesos project <http://mesos.apache.org/>`__

License
-------

Apache License 2.0

Contributors
------------

Alphabetical list of contributors (not necessarily up-to-date),
generated by command
``git log --format='%aN' | sort -u | sed -e 's/^/\- /'``:

-  Andrew Teixeira
-  Chris Rebert
-  Felix Bechstein
-  jfarrell
-  Jing Dong
-  Konrad Scherer
-  krall
-  Kyle Anderson
-  Oriol Fitó
-  Paul Otto
-  Rhommel Lamas
-  Sam Stoelinga
-  Sean McLaughlin
-  Sophie Haskins
-  Tadas Vilkeliskis
-  Tomas Barton
-  Tom Stockton
-  William Leese

.. |Puppet Forge| image:: http://img.shields.io/puppetforge/v/deric/mesos.svg
   :target: https://forge.puppetlabs.com/deric/mesos
.. |Build Status| image:: https://travis-ci.org/deric/puppet-mesos.png
   :target: https://travis-ci.org/deric/puppet-mesos
