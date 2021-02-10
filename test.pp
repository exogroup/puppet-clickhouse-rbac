$rbac = {
  'rw' => {
    'users' => [
      'rw_user1',
      'rw_user2',
      'rw_user3',
    ],
    'grants' => [
      {
        'table'      => 'default.*',
        'privileges' => [ 'SELECT', 'INSERT '],
      },
    ],
  },
  'monitor' => {
    'users' => [
      'monitor_user1',
    ],
    'grants' => [
      {
        'table'      => 'system.*',
        'privileges' => 'SELECT',
      },
      {
        'table'      => '_temporary_and_external_tables.*',
        'privileges' => 'SELECT',
      },
    ],
  },
  'ro' => {
    'users' => [
      'ro_user1',
      'monitor',
    ],
    'grants' => [
      {
        'table'      => 'default.*',
        'privileges' => 'SELECT',
      }
    ],
  },
}

$rbac.each |$role, $settings| {
  # Create users
  ensure_resource('clickhouse_user', $settings['users'])

  # Create role
  clickhouse_role { $role:
    profile => 'default',
  }

  $settings['grants'].each |$grant| {
    $table = $grant['table']
    $privileges = $grant['privileges']
    clickhouse_grant { "${role}/${table}":
      user       => $role,
      table      => $table,
      privileges => $privileges
    }
  }

  clickhouse_grant_role { $role:
    user => $settings['users'],
  }
}
