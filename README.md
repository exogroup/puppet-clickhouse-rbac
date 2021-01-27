# puppet-clickhouse-rbac

### Module Description

The `clickhouse-rbac` puppet module allows management of ClickHouse resources such as users, grants,
quotas and settings profiles using SQL statements.

### Usage

#### Users
```
clickhouse_user { 'foo':
  ensure        => 'present',
  password_hash => sha256('bar'),
  host_ip       => [ '::/0' ],
  host_names    => [],
  host_like     => [],
  host_regexp   => [],
  profile       => 'myprofile',
  distributed   => false,
}
```

`ensure`: Defines if the resource should be _present_ or _absent_  
`password_hash`: SHA256 password hash for the user. ClickHouse supports other types of hashes, but this module only supports SHA256.  
`host_ip`: Array of allowed user host IPs. (default: `::/0`)
`host_names`: Array of allowed user host names.  
`host_like`: Array of allowed user host LIKEs.  
`host_regexp`: Array of allowed user host regular expressions.  
`profile`: Name of the settings profile to associate to the user.  
`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)  

See:
* https://ClickHouse.tech/docs/en/sql-reference/statements/create/user/  
* https://ClickHouse.tech/docs/en/sql-reference/statements/alter/user/

#### Grants
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
`user`: User to apply the grant on.  
`table`: Table to apply the grant on. Must be in the format `<dbname>.<table>` and wildcard for table can be used `<dbname>.*`.  
`privileges`: List of privileges to assign to the grant. Can be specified as Array or String.  
`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)  

See:
* https://ClickHouse.tech/docs/en/sql-reference/statements/grant/

#### Profiles
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
`settings`: Hash containing settings for the profile.  
`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)  

See:
* https://ClickHouse.tech/docs/en/operations/access-rights/#settings-profiles-management
* https://ClickHouse.tech/docs/en/sql-reference/statements/create/settings-profile/

#### Quotas
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
`user`: User(s) to apply the quota on.  
`interval`: Interval duration in seconds (default: `3600`)  
`max_*`: Please refer to the link below for further details on those parameters.  
`distributed`: Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)  

See:
* https://ClickHouse.tech/docs/en/operations/quotas/

### Facts

The module provides some useful facts regarding the current ClickHouse node.

`clickhouse_cluster_name`: Name of the cluster as defined in `metrika.xml`.  
`clickhouse_shard_num`: Current node's shard number.  
`clickhouse_replica_num`: Current node's replica number.  
`clickhouse_version`: Current node's ClickHouse server version.  

### Known issues/limitations

#### clickhouse_user

* The password hash for an user is read from the filesystem because, at the current time, there’s no way
  to get it by executing SQL statements. There might be some corner cases in which this might not work:
  eg. using an SSH tunnel to reach CH from another machine, executing puppet as an unprivileged user
  which has no read access to CH `access` directory.
* Support for SHA256 password hash only. Should be easy to implement a new hash type.
* There might be some issues when specifying loopback addresses for the `host_*` parameters due to ClickHouse
  converting internally those addresses to LOCAL. Similar issues might be seen when specifying overlapping
  addresses/subnets.

#### clickhouse_quota

* Quotas are recreated on update instead of being ALTERed. This is due to ClickHouse creating multiple
  rows which are not easy to manage when updating an existent quota with a different interval duration.
  This has the drawback of assigning a new ID to the quota each time it's changed.

#### clickhouse_profile

* A workaround is required for https://github.com/ClickHouse/ClickHouse/issues/18231 or at least prevent execution
  depending on the server version. This issue could be hit when removing a `SETTINGS PROFILE` which has already
  been assigned to an user.

### Contributions

Contributions are always welcome! If you feel there's something that can be improved/implemented, then
feel free to submit your changes a PRs. Thank you!
