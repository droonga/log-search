: ${ROLE:=stand-alone}

BASE_URL=https://raw.githubusercontent.com/droonga/log-search/master/ubuntu
GROONGA_ADMIN_VERSION=0.9.1

case $(uname) in
  Darwin|*BSD|CYGWIN*) sed="sed -E" ;;
  *)                   sed="sed -r" ;;
esac

ensure_root() {
  if [ "$EUID" != "0" ]; then
    echo "You must run this script as the root."
    exit 1
  fi
}

exist_command() {
  type "$1" > /dev/null 2>&1
}

setup_as_log_search_node() {
  if ! exist_command groonga
  then
    echo "Installing Groonga..."
    add-apt-repository -y ppa:groonga/ppa
    apt-get update
    apt-get install -y groonga
  fi

  if [ ! -d /usr/share/groonga/html/groonga-admin ]
  then
    echo "Installing Groonga admin page..."
    cd /tmp
    wget http://packages.groonga.org/source/groonga-admin/groonga-admin-$GROONGA_ADMIN_VERSION.tar.gz
    tar xvf groonga-admin-$GROONGA_ADMIN_VERSION.tar.gz
    sudo cp -r groonga-admin-$GROONGA_ADMIN_VERSION/html /usr/share/groonga/html/groonga-admin
  fi

  # mkdir ~/groonga-log-search
  # groonga -n ~/groonga-log-search/db quit
  # groonga -d \
  #         -p 10041 \
  #         --protocol http \
  #         --document-root /usr/share/groonga/html/groonga-admin \
  #         ~/groonga-log-search/db

  echo "Installing Fluentd plugins for a log-search-node..."
  td-agent-gem install fluent-plugin-secure-forward
  td-agent-gem install fluent-plugin-groonga

  if [ "$ROLE" = "log-search-node" ]
  then
    curl -o /etc/td-agent/td-agent.conf "$BASE_URL/log-search-node/td-agent.conf"
  fi
}

setup_as_log_parsing_node() {
  echo "Installing Fluentd plugins for a log-parsing-node..."
  td-agent-gem install fluent-plugin-secure-forward
  td-agent-gem install fluent-plugin-forest
  td-agent-gem install fluent-plugin-parser
  td-agent-gem install fluent-plugin-record-reformer

  if [ "$ROLE" = "log-parsing-node" ]
  then
    curl -o /etc/td-agent/td-agent.conf "$BASE_URL/log-parsing-node/td-agent.conf"
  fi
}

setup_as_monitoring_target() {
  echo "Installing Fluentd plugins for a monitoring-target..."
  td-agent-gem install fluent-plugin-secure-forward
  td-agent-gem install fluent-plugin-config-expander

  echo "Updating permission of the system log file for monitoring..."
  chmod g+r /var/log/syslog
  chgrp td-agent /var/log/syslog

  if [ "$ROLE" = "monitoring-target" ]
  then
    curl -o /etc/td-agent/td-agent.conf "$BASE_URL/monitoring-target/td-agent.conf"
  fi
}

install() {
  echo "Installing and activating npd..."
  apt-get install ntp
  service ntp restart

  echo "Installing Fluentd..."
  curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh | sh

  echo "Preparing the buffer directory..."
  mkdir -p /var/spool/td-agent/buffer/
  chown -R td-agent:td-agent /var/spool/td-agent/

  if [ "$ROLE" = "log-search-node" -o "$ROLE" = "stand-alone" ]
  then
    setup_as_log_search_node
  fi

  if [ "$ROLE" = "log-parsing-node" -o "$ROLE" = "stand-alone" ]
  then
    setup_as_log_parsing_node
  fi

  if [ "$ROLE" = "monitoring-target" -o "$ROLE" = "stand-alone" ]
  then
    setup_as_monitoring_target
  fi

  if [ "$ROLE" = "stand-alone" ]
  then
    curl -o /etc/td-agent/td-agent.conf "$BASE_URL/stand-alone/td-agent.conf"
  fi

  service td-agent restart
}

ensure_root

install

exit 0
