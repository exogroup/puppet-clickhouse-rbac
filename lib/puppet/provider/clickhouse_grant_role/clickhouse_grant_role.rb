require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_grant_role).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage grants for roles on ClickHouse server'

  def self.instances
    sql = (<<~SQL)
      SELECT
        g.*
      FROM
        system.role_grants g
      INNER JOIN system.roles r
      ON r.name = g.granted_role_name
      WHERE r.storage = 'local directory'
    SQL

    begin
      rows = query(sql, true)
    rescue
      rows = Hash.new
      rows['data'] = Array.new
    end
    grants = Hash.new
    rows['data'].each do |row|
      role = row['granted_role_name']
      user = row['user_name']
      grants[role] = Array.new if grants[role].nil?
      grants[role].push(user)
    end
    grants.map do |name, user|
      new(
        ensure: :present,
        name:   name,
        user:   user.sort,
      )
    end
  end

  mk_resource_methods

  def flush
    if @resource[:ensure] == :absent
      sql = "REVOKE #{name} FROM ALL"
      query(sql)
      @property_hash.clear
      return
    end
    manage(diff(:user))
  end

  def manage(diff)
    name = @resource[:name]
    unless diff[:grant].empty?
      users = diff[:grant].map(&:strip).join(', ')
      sql = "GRANT #{name} TO #{users}"
      query(sql)
    end
    unless diff[:revoke].empty?
      users = diff[:grant].map(&:strip).join(', ')
      sql = "GRANT #{name} TO #{users}"
      query(sql)
    end
  end

  def user=(x)
  end
  
end