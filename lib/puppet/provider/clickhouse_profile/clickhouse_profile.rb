require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_profile).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage settings profiles on ClickHouse server'

  def self.instances
    sql = (<<~SQL)
      SELECT
        *
      FROM system.settings_profiles
      WHERE storage = 'local directory'
    SQL

    begin
      rows = query(sql, true)
    rescue
      rows = Hash.new
      rows['data'] = Array.new
    end
    rows['data'].map do |row|
      new(
        ensure:   :present,
        id:       row['id'],
        name:     row['name'],
        settings: get_profile_settings(row['name']),
      )
    end
  end

  mk_resource_methods

  def flush
    name = @resource[:name]

    if @resource[:ensure] == :absent
      sql = "DROP SETTINGS PROFILE '#{name}' #{on_cluster}"
      query(sql)
      @property_hash.clear
      return
    end

    sql = (<<~SQL)
      #{action} SETTINGS PROFILE '#{name}' #{on_cluster}
      SETTINGS #{profile_settings}
    SQL

    query(sql)
  end

  def action
    @property_hash[:id].to_s.empty?? 'CREATE' : 'ALTER'
  end

  def profile_settings
    @resource[:settings].to_h.map do |key,val|
      "#{key} = '#{val}'"
    end.join(', ')
  end

  def settings=(x)
  end

end
