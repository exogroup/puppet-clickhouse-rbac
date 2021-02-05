# Puppet provider for clickhouse
require 'json'

class Puppet::Provider::Clickhouse < Puppet::Provider
  initvars

  ENV['PATH'] += ':/bin:/usr/bin:/usr/local/bin'

  commands clickhouse_client: 'clickhouse-client'

  def self.prefetch(resources)
    instances.each do |provider|
      if resource = resources[provider.name]
        resource.provider = provider
      end
    end
  end

  # Converts the argument to integer if not nil
  def self.parseInt(val)
    val.to_i if val
  end

  # Performs difference between values for a property
  # in @property_hash and @resource. Returns the values
  # that need to be revoked and granted.
  def diff(sym)
    old_vals = Array(@property_hash[sym])
    new_vals = Array(@resource[sym])

    result = Hash.new
    result[:revoke] = old_vals - new_vals
    result[:grant]  = new_vals - old_vals

    result
  end

  # Performs a query in Clickhouse.
  # Supports returning results as-is or in JSON format.
  def self.query(sql, json=false)
    sql_flatten = sql.gsub(/[\n|\s]+/,' ').strip
    opts = [ '-q', sql_flatten ]
    if json
      opts << '--format'
      opts << 'JSON'
    end
    res = clickhouse_client(opts.flatten.compact)
    json ? JSON.parse(res) : res.strip
  end

  def query(sql, json=false)
    self.class.query(sql, json)
  end

  # Lists RBAC users
  def self.users_and_roles
    sql = (<<~SQL)
      SELECT
        name
      FROM system.users
      WHERE storage = 'local directory'
      UNION ALL
      SELECT
        name
      FROM system.roles
      WHERE storage = 'local directory'
    SQL

    begin
      rows = query(sql).split("\n")
      rows.uniq.sort if rows rescue []
    rescue
      []
    end
  end

  def users
    self.class.users
  end

  # Lists RBAC grants
  def self.grants
    grants = []
    users_and_roles.each do |user_or_role|
      sql = "SHOW GRANTS FOR '#{user_or_role}'"
      begin
        entries = query(sql).split("\n")
        Array(entries).each do |grant|
          grants << grant
        end
      rescue
        []
      end
    end
    grants
  end

  def grants
    self.class.grants
  end

  # Lists RBAC quotas
  def self.quotas
    sql = (<<~SQL)
      SELECT q.*, l.*
      FROM system.quotas q
      LEFT JOIN system.quota_limits l
      ON q.name = l.quota_name
      WHERE q.storage = 'local directory'
    SQL

    begin
      rows = query(sql, true)
      rows['data']
    rescue
      []
    end
  end

  def quotas
    self.class.quotas
  end

  # Returns the settings for the specified profile
  def self.get_profile_settings(name)
    sql = (<<~SQL)
      SELECT
        *
      FROM system.settings_profile_elements
      WHERE profile_name = '#{name}'
    SQL

    rows = query(sql, true)
    res = Hash.new
    rows['data'].each do |row|
      key = row['setting_name']
      val = row['value']
      res[key] = val
    end
    res
  end

  def get_profile_settings(name)
    self.class.get_profile_settings(name)
  end

  # Returns clickhouse server version
  def self.server_version
    version = Facter.value(:clickhouse_version)
    if version.nil?
      sql = "SELECT VERSION()"
      version = query(sql)
    end
    version
  end

  def version
    self.class.server_version
  end

  # FIXME: How to check if distributed_ddl is enabled in config?
  def on_cluster
    cluster_name = Facter.value(:clickhouse_cluster_name).to_s
    "ON CLUSTER '#{cluster_name}'" if !cluster_name.empty? && @resource[:distributed] == :true
  end

  # FIXME: This should be improved
  def self.has_rbac_profile_bug
    Puppet::Util::Package.versioncmp(server_version, '20.8.11.17') <= 0
  end

  def has_rbac_profile_bug
    self.class.has_rbac_profile_bug
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

end
