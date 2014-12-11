log-search
==========

Example configurations and others to construct log-search system based on a Droonga cluster.

See also: https://github.com/project-hatohol/hatohol/wiki/Log-search

## How to construct a stand-alone node

You can construct a stand-alone node just for experiments.
It should work as a monitoring target node, a log parsing node, and a log search node.
If you are using Ubuntu Trusty:

    $ curl "https://raw.githubusercontent.com/droonga/log-search/master/ubuntu/install.sh" | sudo bash

Otherwise (if you are using CentOS) apply all steps to setup each node to a server, except `/etc/td-agent/td-agent.conf`.
Instead, you should use the file `centos/stand-alone/td-agent.conf` in this repository.

Steps to try the log-search system:

 1. Go to the [Groonga's admin page](http://localhost:10041/)
 2. Run `logger (message)` like `logger foobar` on your terminal console.
 3. Reload the admin page. Then you'll see a new `Logs` table automatically created by log-search system.

## How to configure log-search system to work with Droonga

Use `droonga-engine` and `droonga-http-server` instead of `groonga`.
Then the log-search system automatically uses the Droonga cluster as its backend.

To configure `droonga-http-server` for the log-search system, use `10041` as the port, specify the path to the `droonga-admin` directory as the document root, and disable the response cache.
For example:

~~~
% sudo droonga-http-server-configure \
         --port 10041 \
         --document-root /usr/share/groonga/html/groonga-admin \
         --cache-size 0
~~~

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
% sudo td-agent-gem install fluent-plugin-secure-forward
% sudo td-agent-gem install fluent-plugin-groonga
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
% sudo td-agent-gem install fluent-plugin-secure-forward
% sudo td-agent-gem install fluent-plugin-forest
% sudo td-agent-gem install fluent-plugin-parser
% sudo td-agent-gem install fluent-plugin-record-reformer
~~~

Configure Fluentd: same to CentOS

Create `/etc/td-agent/td-agent.conf`: same to CentOS

Start Fluentd: same to CentOS


### Monitoring target node

Install the following Fluentd plugins:

~~~
% sudo td-agent-gem install fluent-plugin-secure-forward
% sudo td-agent-gem install fluent-plugin-config-expander
~~~

Configure Fluentd:

~~~
% sudo mkdir -p /var/spool/td-agent/buffer/
% sudo chown -R td-agent:td-agent /var/spool/td-agent/
% sudo chmod g+r /var/log/syslog
% sudo chgrp td-agent /var/log/syslog
~~~

You have to use `/var/log/syslog` instead of `/var/log/messages` on Ubuntu.

Create `/etc/td-agent/td-agent.conf`:

~~~
<source>
  type config_expander
  <config>
    type tail
    path /var/log/syslog
    pos_file /var/log/td-agent/messages.pos
    tag raw.messages.log.${hostname}
    format none
  </config>
</source>

<match raw.*.log.**>
  type secure_forward
  shared_key fluentd-secret
  self_hostname node1.example.com
  <server>
    host parser1.example.com
  </server>
  <server>
    host parser2.example.com
  </server>

  buffer_type file
  buffer_path /var/spool/td-agent/buffer/secure-forward
  flush_interval 1
</match>
~~~

The path to the log file is `/var/log/syslog`, not `/var/log/messages`.
All other configurations are same to CentOS.

Start Fluentd: same to CentOS

