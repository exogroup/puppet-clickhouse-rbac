require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_user).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage users on ClickHouse server'

  def self.instances
    sql = (<<~SQL)
      SELECT
        u.*,
        s.inherit_profile AS profile
      FROM system.users u
      LEFT JOIN system.settings_profile_elements s
      ON u.name = s.user_name
      WHERE storage = 'local directory'
    SQL

    begin
      rows = query(sql, true)
    rescue
      rows = Hash.new
      rows['data'] = Array.new
    end
    rows['data'].map do |row|
      # Retrieve password hash from user file.
      # ClickHouse doesn't seem to support retrieving it via SQL.
      # FIXME: Should access dir path be configurable?
      get_pwd_cmd = "/bin/grep -oP \"BY '\\K[^']+\" /var/lib/clickhouse/access/#{row['id']}.sql | /bin/tr -d '\\n'"
      password_hash = execute(get_pwd_cmd, :failonfail => false)
      new(
        ensure:        :present,
        password_hash: password_hash,
        profile:       row['profile'].to_s, # To match against empty string
        id:            row['id'],
        name:          row['name'],
        host_ip:       row['host_ip'],
        host_names:    row['host_names'],
        host_regexp:   row['host_names_regexp'],
        host_like:     row['host_names_like'],
      )
    end
  end

  mk_resource_methods

  def flush
    user = @resource[:name]

    if @resource[:ensure] == :absent
      sql = "DROP USER '#{user}' #{on_cluster}"
      query(sql)
      @property_hash.clear
      return
    end

    sql = "#{action} USER '#{user}' #{on_cluster} IDENTIFIED WITH #{identified_with} #{host} #{settings_profile}"
    query(sql)
  end

  def settings_profile
    profile = @resource[:profile].to_s
    "SETTINGS PROFILE '#{profile}'" unless profile.empty?
  end

  def action
    @property_hash[:id].to_s.empty?? 'CREATE' : 'ALTER'
  end

  def identified_with
    password_hash = @resource[:password_hash].to_s
    password_hash.empty?? 'NO_PASSWORD' : "SHA256_HASH BY '#{password_hash}'"
  end

  def host
    data = {
      'IP'     => @resource[:host_ip],
      'NAME'   => @resource[:host_names],
      'LIKE'   => @resource[:host_like],
      'REGEXP' => @resource[:host_regexp],
    }
    # Remove the empty values and loop over the hash
    res = data.delete_if { |k, v| Array(v).empty? }.map do |type, hosts|
      # Compose the SQL statement for current type (eg. IP 'ip1', 'ip2', ...)
      "#{type.upcase} ".concat(
        # Quote values and separe them by commas
        hosts.compact.map do |host|
          "'#{host}'"
        end.join(', ')
      )
    # Separe the generated SQL statements by commas
    end.join(', ')
    # Return the full SQL statement or null if empty
    "HOST #{res}" unless res.strip.empty? rescue nil
  end

  def profile=(x)
  end

  def host_ip=(x)
  end

  def host_names=(x)
  end

  def host_like=(x)
  end

  def host_regexp=(x)
  end

  def password_hash=(x)
  end
end
