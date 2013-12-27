define oxid::mysql::createdb (
  $db,
  $host    = $oxid::mysql::params::default_host,
  $port    = $oxid::mysql::params::default_port,
  $user    = $oxid::mysql::params::default_user,
  $password,
  $charset = $oxid::mysql::params::default_db_charset) {
  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  exec { "${name}: mysql create ${db} on ${host} with charset ${charset}":
    path    => $oxid::params::path,
    command => "mysql --host='${host}' --port=$port --user='${user}' --password='${password}' -e \"create database ${db} charset=${charset}\"",
    require => Class[::mysql::client]
  }
}

define oxid::mysql::grantdb (
  $db,
  $host           = $oxid::mysql::params::default_host,
  $port           = $oxid::mysql::params::default_port,
  $user           = $oxid::mysql::params::default_user,
  $password,
  $grant_user     = undef,
  $grant_password = undef,
  $grant_host     = 'localhost',
  $grant_privs    = 'ALL') {
  $real_grant_user = $grant_user ? {
    undef   => $user,
    default => $grant_user
  }
  $real_grant_password = $grant_user ? {
    undef   => $password,
    default => $grant_password
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  exec { "${name}: mysql grant ${grant_privs} on ${db}.* to  ${real_grant_user}@${grant_host}":
    command => "mysql --host='${host}' --port=$port --user='${user}' --password='${password}' -e \"GRANT ${grant_privs} ON ${db}.* TO ${real_grant_user}@${grant_host} IDENTIFIED BY '${real_grant_password}'; FLUSH PRIVILEGES;\"",
    path    => $oxid::params::path,
    require => Class[::mysql::client]
  }
}

define oxid::mysql::dropdb (
  $db,
  $host = $oxid::mysql::params::default_host,
  $port = $oxid::mysql::params::default_port,
  $user = $oxid::mysql::params::default_user,
  $password) {
  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  exec { "${name}: mysql drop ${db} on ${host}":
    path    => $oxid::params::path,
    command => "mysql --host='${host}' --port=$port --user='${user}' --password='${password}' -e \"drop database IF EXISTS ${db};\"",
    require => Class[::mysql::client]
  }
}

define oxid::mysql::execFile (
  $db,
  $host        = $oxid::mysql::params::default_host,
  $port        = $oxid::mysql::params::default_port,
  $user        = $oxid::mysql::params::default_user,
  $password,
  $source      = undef,
  $extract_cmd = undef,
  $unless      = undef,
  $cwd         = undef,
  $charset     = undef,
  $timeout     = 300) {
  if $source != undef {
    $myfile = $source
  } else {
    $myfile = $name
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  $extra_options = $charset ? {
    undef   => "",
    default => " --default-character-set=${charset}"
  }

  if $extract_cmd != undef {
    if !defined(Class[oxid::package::packer]) {
      include oxid::package::packer
    }

    exec { "${name}: ${extract_cmd} < ${source} | mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='******' '${db}'"
    :
      command => "${extract_cmd} < ${source} | mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}'",
      path    => $oxid::params::path,
      unless  => $unless,
      cwd     => $cwd,
      timeout => $timeout,
      require => Class[::mysql::client, oxid::package::packer]
    }
  } else {
    exec { "${name}: mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='******' '${db}' < ${myfile}":
      command => "mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}' < ${myfile}",
      path    => $oxid::params::path,
      unless  => $unless,
      cwd     => $cwd,
      timeout => $timeout,
      require => Class[::mysql::client]
    }
  }
}

define oxid::mysql::execDirectory (
  $db,
  $host      = $oxid::mysql::params::default_host,
  $port      = $oxid::mysql::params::default_port,
  $user      = $oxid::mysql::params::default_user,
  $password,
  $directory = undef,
  $pattern   = "*.sql",
  $charset   = undef,
  $timeout   = 300) {
  if $directory != undef {
    $mydir = $directory
  } else {
    $mydir = $name
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  $extra_options = $charset ? {
    undef   => "",
    default => " --default-character-set=${charset}"
  }

  exec { "${name}: find '${mydir}' -iname '${pattern}' | while read i; do mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='******' '${db}' < \"\$i\" ; done"
  :
    command => "find '${mydir}' -iname '${pattern}' | while read i; do mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}' < \"\$i\" ; done",
    path    => $oxid::params::path,
    timeout => $timeout,
    require => Class[::mysql::client]
  }

}

define oxid::mysql::execSQL (
  $db,
  $host    = $oxid::mysql::params::default_host,
  $port    = $oxid::mysql::params::default_port,
  $user    = $oxid::mysql::params::default_user,
  $password,
  $query   = undef,
  $unless  = undef,
  $timeout = 300) {
  $myquery = $query ? {
    undef   => $name,
    default => $query
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  exec { "${myquery}":
    command => "mysql --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}' -e \"${myquery}\"",
    path    => $oxid::params::path,
    unless  => $unless,
    timeout => $timeout,
    require => Class[::mysql::client]
  }
}
