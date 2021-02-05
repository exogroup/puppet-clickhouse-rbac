require_relative '../clickhouse'
Puppet::Type.type(:clickhouse_grant).provide(:clickhouse, parent: Puppet::Provider::Clickhouse) do
  desc 'Manage grants on ClickHouse server'

  def self.instances
    instances = []
    grants.each do |grant|
      next unless match = grant.match(/^GRANT\s(.+)\sON\s(.+)\sTO\s(\w+)\s?(.*)?$/)
      privileges, table, user, rest  = match.captures
      # Clean and reorder privileges sequence to have a comparable array
      privileges = privileges.scan(/(?:\(.*?\)|[^,])+/).map(&:strip).sort
      # Retrieve and set options
      options = rest =~ /WITH\sGRANT\sOPTION/ ? ['GRANT'] : ['NONE']
      # Populate instances array
      instances << new(
        name:       "#{user}/#{table}",
        ensure:     :present,
        privileges: privileges,
        table:      table,
        user:       user,
        options:    options,
      )
    end
    instances
  end

  mk_resource_methods

  # GRANTs privileges and options for an user
  def grant(privileges = [], options = [])
    user  = @resource[:user]
    table = @resource[:table]

    unless privileges.empty?
      sql_privileges = privileges.join(', ')
      sql = "GRANT #{on_cluster} #{sql_privileges} ON #{table} TO #{user}"
      # Append GRANT OPTION only if it was previously enabled and if not explicitly requested
      if Array(@property_hash[:options]).include?('GRANT') and !options.include?('NONE')
        sql << ' WITH GRANT OPTION'
      end
      query(sql)
    end

    # Set GRANT OPTION if explicitly requested
    if options.include?('GRANT')
      privileges_full = (Array(privileges) + Array(@property_hash[:privileges])).sort.uniq
      privileges_sql = privileges_full.join(', ')
      sql = "GRANT #{on_cluster} #{privileges_sql} ON #{table} TO #{user} WITH GRANT OPTION"
      query(sql)
    end
  end

  # REVOKEs privileges and options for an user
  def revoke(privileges = [], options = [])
    # For some reason @resource is not populated when purging resources
    # using `puppet resource`. Using @property_hash seems to work.
    user  = @property_hash[:user]
    table = @property_hash[:table]

    unless privileges.empty?
      privileges_sql = privileges.join(', ')
      sql = "REVOKE #{on_cluster} #{privileges_sql} ON #{table} FROM #{user}"
      query(sql)
    end

    if options.include?('GRANT')
      sql = "REVOKE #{on_cluster} GRANT OPTION FOR ALL ON #{table} FROM #{user}"
      query(sql)
    end
  end

  def flush
    privileges = diff(:privileges)
    options = diff(:options)
    revoke(privileges[:revoke], options[:revoke])
    grant(privileges[:grant], options[:grant])
  end

  # Override setters to avoid changes on @property_hash
  def options=(x)
  end

  def privileges=(x)
  end

  def user=(x)
  end

end
