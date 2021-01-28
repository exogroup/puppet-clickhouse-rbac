# puppet-clickhouse-rbac

## Module Description

The `clickhouse-rbac` puppet module allows management of ClickHouse resources such as users, grants,
quotas and settings profiles using SQL statements.

## Usage

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

##### Parameters
See:
* https://clickhouse.tech/docs/en/sql-reference/statements/create/user/
* https://clickhouse.tech/docs/en/sql-reference/statements/alter/user/

###### ensure
Defines if the resource should be _present_ or _absent_.

###### password_hash
SHA256 password hash for the user.  
ClickHouse supports other types of hashes, but this module only supports SHA256.

###### host_ip
Array of allowed user host IPs. (default: `::/0`)

###### host_names
Array of allowed user host names.

###### host_like
Array of allowed user host LIKEs.

###### host_regexp
Array of allowed user host regular expressions.

###### profile
Name of the settings profile to associate to the user.

###### distributed
Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)


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
##### Parameters
This type is highly based on `mysql_grant`, so it should work similarly.  
The resource name must match `<user>/<table>` parameters, otherwise it'll throw an error.

See:
* https://clickhouse.tech/docs/en/sql-reference/statements/grant/

###### ensure
Defines if the resource should be _present_ or _absent_.

###### user
User to apply the grant on.

###### table
Table to apply the grant on. Must be in the format `<dbname>.<table>` and wildcard for tables can also be used `<dbname>.*`.

###### privileges
List of privileges to assign to the grant. Can be specified as `Array` or `String`.

###### distributed
Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)


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
##### Parameters
See:
* https://clickhouse.tech/docs/en/operations/access-rights/#settings-profiles-management
* https://clickhouse.tech/docs/en/sql-reference/statements/create/settings-profile/


###### ensure
Defines if the resource should be _present_ or _absent_

###### settings
Hash containing settings for the profile.

###### distributed
Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)


#### Quotas
```
clickhouse_quota { 'myquota':
  ensure         => 'present',
  interval       => 'second',
  keys           => 'user_name',
  duration       => 3600,
  randomized     => false,
  queries        => 0,
  errors         => 0,
  read_rows      => 0,
  read_bytes     => 0,
  result_rows    => 0, 
  result_bytes   => 0,
  execution_time => 0,
  user           => 'foo',
  distributed    => true,
}
```

##### Parameters
See:
* https://clickhouse.tech/docs/en/operations/quotas/
* https://clickhouse.tech/docs/en/operations/system-tables/quotas/

###### ensure
Defines if the resource should be _present_ or _absent_.

###### user
User(s) to apply the quota on.

###### keys
Key specifies how the quota should be shared.  
If two connections use the same quota and key, they share the same amounts of resources.  
Valid values for this parameter are:
  * `none`  
    All users share the same quota. (default)
  * `user_name`  
    Connections with the same user name share the same quota.
  * `ip_address`  
    Connections from the same IP share the same quota.
  * `client_key`  
    Connections with the same key share the same quota.  
  * `[ user_name, client_key ]`  
    Connections with the same `client_key` share the same quota.  
    If a key isn’t provided by a client, the quota is tracked for `user_name`.
  * `[ client_key, ip_address ]`  
    Connections with the same `client_key` share the same quota.  
    If a key isn’t provided by a client, the quota is tracked for `ip_address`.

###### interval
Type of interval. It can be one of: `second` (default), `minute`, `hour`, `day`, `week`, `month`, `quarter`, `year`.

###### duration
Interval duration depending on the specified `interval`. (default: `3600`)

###### randomized
Randomize the interval (default: `false`)

###### queries
Max amount of queries.

###### errors
Max amount of queries that threw an exception.

###### read_rows
Max amount of source rows read from tables for running the query on all remote servers.

###### read_bytes
Max amount of bytes read from tables for running the query on all remote servers.

###### result_rows
Max amount of rows given as a result.

###### result_bytes
Max amount of bytes given as a result.

###### execution_time
Max query execution time, in seconds (wall time).

###### distributed
Determine whether to use the `ON CLUSTER` statement for queries. (default: `true`)


### Facts
The module provides some useful facts regarding the current ClickHouse node.

###### clickhouse_cluster_name
Name of the cluster as defined in `metrika.xml`.

###### clickhouse_shard_num
Current node's shard number.

###### clickhouse_replica_num
Current node's replica number.

###### clickhouse_version
Current node's ClickHouse server version.


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
Contributions are always welcome!  
If you feel there's something that can be improved/implemented, then feel free to submit your changes as PRs.
