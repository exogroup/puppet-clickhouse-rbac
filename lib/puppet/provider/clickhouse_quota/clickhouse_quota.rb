require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_quota).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage quotas on ClickHouse server'

  def self.instances
    instances = []
    quotas.map do |row|
      new(
        ensure:             :present,
        id:                 row['id'],
        name:               row['name'],
        interval:           row['duration'],
        max_queries:        row['max_queries'],
        max_errors:         row['max_errors'],
        max_result_rows:    row['max_result_rows'],
        max_result_bytes:   row['max_result_bytes'],
        max_read_rows:      row['max_read_rows'],
        max_read_bytes:     row['max_read_bytes'],
        max_execution_time: row['max_execution_time'],
        user:               row['apply_to_list'].sort,
      )
    end
  end

  mk_resource_methods

  # All the magic goes here
  def flush
    quota_name = @resource[:name]
    quota_interval = @resource[:interval]

    # Drop quota when needed
    if @property_hash[:ensure] == :absent
      sql = "DROP QUOTA '#{quota_name}' #{on_cluster}"
      query(sql)
      @property_hash.clear
      return
    end

    # FIXME: 'OR REPLACE' is used in place of 'ALTER' to avoid issues when
    # changing the duration interval, resulting in multiple rows being
    # created in the system.quota_limits table. Needs proper implementation.
    sql = "CREATE QUOTA OR REPLACE '#{quota_name}' #{on_cluster} FOR INTERVAL #{quota_interval} SECOND #{quota_settings} #{quota_user}"
    query(sql)
  end

  # Return quota settings for use in SQL statement
  def quota_settings
    settings = []
    {
      'MAX QUERIES'        => @resource[:max_queries],
      'MAX ERRORS'         => @resource[:max_errors],
      'MAX RESULT ROWS'    => @resource[:max_result_rows],
      'MAX RESULT BYTES'   => @resource[:max_result_bytes],
      'MAX READ ROWS'      => @resource[:max_read_rows],
      'MAX READ BYTES'     => @resource[:max_read_bytes],
      'MAX EXECUTION TIME' => @resource[:max_execution_time],
    }.each do |setting, value|
      settings << "#{setting} = #{value}" unless value.nil?
    end
    settings.empty?? 'NO LIMITS' : settings.join(', ')
  end

  # Return quota user for use in SQL statement
  def quota_user
    user = @resource[:user].join(', ')
    "TO #{user}" unless user.empty?
  end
end
