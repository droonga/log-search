log-search
==========

Example configurations and others to construct log-search system based on a Droonga cluster.

See also: https://github.com/project-hatohol/hatohol/wiki/Log-search

## How to construct a stand-alone node

You can construct a stand-alone node just for testing.
It should work as a monitoring target node, a log parsing node, and a log search node.

To do it, apply all steps to setup each node to a server, except `/etc/td-agent/td-agent.conf`.
Instead, you should use the file `stand-alone/td-agent.conf` in this repository.

## How to construct nodes with Ubuntu server

Descriptions in the page above is written for CentOS servers.
There are some difference for Ubuntu servers.

### All nodes

Install and run npd:

~~~
% sudo apt-get install ntp
% sudo service ntp start
~~~

You have to use `apt` instead of `yum`.

Install Fluentd:

~~~
% curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh | sudo sh
~~~

Note, you must choose the correct installation script for your Ubuntu server.
Find it from [the list of available scripts](http://docs.fluentd.org/ja/articles/install-by-deb).

### Log search node

Install the following Fluentd plugins:

~~~
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-secure-forward
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-groonga
~~~

The path to the `gem` command is different from the one on CentOS server.

Configure Fluentd: same to CentOS.

Create `/etc/td-agent/td-agent.conf`: same to CentOS.

Start Fluentd: same to CentOS.

Install Groonga:

~~~
% sudo add-apt-repository -y ppa:groonga/ppa
% sudo apt-get update
% sudo apt-get install -y groonga
% cd /tmp
% wget http://packages.groonga.org/source/groonga-admin/groonga-admin-0.9.1.tar.gz
% tar xvf groonga-admin-0.9.1.tar.gz
% sudo cp -r groonga-admin-0.9.1/html /usr/share/groonga/html/groonga-admin
% mkdir ~/groonga-log-search
% groonga -n ~/groonga-log-search/db quit
% groonga -d \
          -p 10041 \
          --protocol http \
          --document-root /usr/share/groonga/html/groonga-admin \
          ~/groonga-log-search/db
~~~


### Log parsing node

Install the following Fluentd plugins:

~~~
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-secure-forward
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-forest
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-parser
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-record-reformer
~~~

Configure Fluentd: same to CentOS

Create `/etc/td-agent/td-agent.conf`: same to CentOS

Start Fluentd: same to CentOS


### Monitoring target node

Install the following Fluentd plugins:

~~~
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-secure-forward
% sudo /opt/td-agent/embedded/bin/gem install fluent-plugin-config-expander
~~~

Configure Fluentd:

~~~
% sudo mkdir -p /var/spool/td-agent/buffer/
% sudo chown -R td-agent:td-agent /var/spool/td-agent/
% sudo chmod g+r /var/log/syslog
% sudo chgrp td-agent /var/log/syslog
~~~

You have to use `/var/log/syslog` instead of `/var/log/messages` on Ubuntu.

Create `/etc/td-agent/td-agent.conf`: same to CentOS

Start Fluentd: same to CentOS

