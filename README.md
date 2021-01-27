# puppet-clickhouse-rbac

## Module Description

The `clickhouse-rbac` module allows management of ClickHouse resources such as users, grants, quotas and settings profiles.
It provides the following types:
  * **clickhouse_user**
  * **clickhouse_grant**
  * **clickhouse_quota**
  * **clickhouse_profile**

## Usage

### Users
* https://clickhouse.tech/docs/en/sql-reference/statements/create/user/  
* https://clickhouse.tech/docs/en/sql-reference/statements/alter/user/

```
clickhouse_user { 'foo':
  ensure        => 'present',
  password_hash => sha256('bar'),
  host_ip       => [],
  host_names    => [],
  host_like     => [],
  host_regexp   => [],
  profile       => 'myprofile',
  distributed   => false,
}
```

`ensure`: Defines if the resource should be _present_ or _absent_

`password_hash`: SHA256 password hash for the user. ClickHouse supports other types of hashes, but this module only supports SHA256.

`host_ip`: Array of allowed user host IPs.

`host_names`: Array of allowed user host names.

`host_like`: Array of allowed user host LIKEs.

`host_regexp`: Array of allowed user host regular expressions.

`profile`: Name of the settings profile to associate to the user

`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)

### Grants
* https://clickhouse.tech/docs/en/sql-reference/statements/grant/

```
clickhouse_grant { 'foo/mydb.mytable':
  ensure      => 'present',
  user        => 'foo',
  table       => 'mydb.mytable',
  privileges  => [
    'INSERT',
    'SELECT',
  ],
  options     => 'GRANT',
  distributed => false,
```

This type is highly based on `mysql_grant`, so it should work similarly.  
The resource name must match `<user>/<table>` parameters, otherwise it'll throw an error.

`ensure`: Defines if the resource should be _present_ or _absent_

`user`: User to apply the grant on

`table`: Table to apply the grant on. Must be in the format `<dbname>.<table>` and wildcard for table can be used `<dbname>.*`.

`privileges`: List of privileges to assign to the grant. Can be specified as Array or String.

`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)


### Profiles
* https://clickhouse.tech/docs/en/operations/access-rights/#settings-profiles-management
* https://clickhouse.tech/docs/en/sql-reference/statements/create/settings-profile/

```
clickhouse_profile { 'myprofile':
  ensure      => 'present',
  settings    => {
    'readonly' => 1,
  }
  distributed => true,
}
```

`ensure`: Defines if the resource should be _present_ or _absent_

`settings`: Hash containing settings for the profile

`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)

### Quotas
* https://clickhouse.tech/docs/en/operations/quotas/

```
clickhouse_quota { 'myquota':
  ensure             => 'present',
  interval           => 3600,
  max_queries        => 10,
  max_errors         => 20,
  max_read_rows      => 30,
  max_read_bytes     => 40,
  max_result_rows    => 50, 
  max_result_bytes   => 60,
  max_execution_time => 70,
  user               => 'myuser',
  distributed        => true,
}
```

`ensure`: Defines if the resource should be _present_ or _absent_

`user`: User(s) to apply the quota on

`interval`: Interval duration in seconds (default: `3600`)

`max_*`: Please refer to the link in the heading for further details on those parameters.

`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)

## Facts

The module provides some useful facts regarding the current Clickhouse node.

`clickhouse_cluster_name`: Name of the cluster as defined in `metrika.xml`.

`clickhouse_shard_num`: Current node's shard number.

`clickhouse_replica_num`: Current node's replica number.

`clickhouse_version`: Current node's clickhouse server version.