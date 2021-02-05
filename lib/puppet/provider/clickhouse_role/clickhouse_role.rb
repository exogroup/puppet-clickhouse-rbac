require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_role).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage roles on ClickHouse server'

  def self.instances
    sql = (<<~SQL)
      SELECT
        r.*,
        s.inherit_profile AS profile
      FROM system.roles r
      LEFT JOIN system.settings_profile_elements s
      ON r.name = s.role_name
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
        ensure:        :present,
        name:          row['name'],
        id:            row['id'],
        profile:       row['profile'],
      )
    end
  end

  mk_resource_methods

  def flush
    role = @resource[:name]

    if @resource[:ensure] == :absent
      sql = "DROP ROLE '#{role}' #{on_cluster}"
      query(sql)
      @property_hash.clear
      return
    end

    sql = "#{action} ROLE '#{role}' #{on_cluster} #{settings_profile}"
    query(sql)
  end

  def action
    @property_hash[:id].to_s.empty?? 'CREATE' : 'ALTER'
  end

  def settings_profile
    profile = @resource[:profile].to_s
    "SETTINGS PROFILE '#{profile}'" unless profile.empty?
  end

end