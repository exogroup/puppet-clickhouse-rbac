require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_quota).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage quotas on ClickHouse server'

  def self.instances
    instances = []
    quotas.map do |row|
      new(
        ensure:         :present,
        name:           row['name'],
        randomized:     row['is_randomized_interval'].to_i == 1 ? :true : :false,
        duration:       row['durations'].first,
        queries:        parseInt(row['max_queries']),
        errors:         parseInt(row['max_errors']),
        result_rows:    parseInt(row['max_result_rows']),
        result_bytes:   parseInt(row['max_result_bytes']),
        read_rows:      parseInt(row['max_read_rows']),
        read_bytes:     parseInt(row['max_read_bytes']),
        execution_time: parseInt(row['max_execution_time']),
        user:           row['apply_to_list'].sort,
        keys:           row['keys'].empty?? [ :none ] : row['keys'].sort,
      )
    end
  end

  mk_resource_methods

  # All the magic goes here
  def flush
    quota_name = @resource[:name]
    quota_duration = @resource[:duration]

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
    sql = (<<~SQL)
      CREATE QUOTA OR REPLACE '#{quota_name}' #{on_cluster}
      #{quota_keys} FOR #{quota_randomized} INTERVAL #{quota_duration}
      SECOND #{quota_settings}
      #{quota_user}
    SQL
    query(sql)
  end

  # Return quota settings for use in SQL statement
  def quota_settings
    settings = []
    {
      'MAX QUERIES'        => @resource[:queries],
      'MAX ERRORS'         => @resource[:errors],
      'MAX RESULT ROWS'    => @resource[:result_rows],
      'MAX RESULT BYTES'   => @resource[:result_bytes],
      'MAX READ ROWS'      => @resource[:read_rows],
      'MAX READ BYTES'     => @resource[:read_bytes],
      'MAX EXECUTION TIME' => @resource[:execution_time],
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

  def quota_randomized
    'RANDOMIZED' if @resource[:randomized] == :true
  end

  def quota_keys
    keys = Array(@resource[:keys]).map(&:to_s).join(', ')
    "KEYED BY #{keys}" unless keys.empty?
  end

end