Puppet::Type.newtype(:clickhouse_grant) do
  @doc = "Manage user grants in ClickHouse"

  autorequire(:clickhouse_user) { self[:user] }

  # List of privileges set by ClickHouse when 'ALL' is specified.
  # In case new privileges are added in future release of ClickHouse
  # then this list needs to be properly updated. Sorry :(
  $all_privileges = [
    'SHOW TABLES',
    'SHOW COLUMNS',
    'SHOW DICTIONARIES',
    'SELECT',
    'INSERT',
    'ALTER',
    'CREATE TABLE',
    'CREATE VIEW',
    'CREATE DICTIONARY',
    'DROP TABLE',
    'DROP VIEW',
    'DROP DICTIONARY',
    'TRUNCATE',
    'OPTIMIZE',
    'SYSTEM MERGES',
    'SYSTEM TTL MERGES',
    'SYSTEM FETCHES',
    'SYSTEM MOVES',
    'SYSTEM SENDS',
    'SYSTEM REPLICATION QUEUES',
    'SYSTEM DROP REPLICA',
    'SYSTEM SYNC REPLICA',
    'SYSTEM RESTART REPLICA',
    'SYSTEM FLUSH DISTRIBUTED',
    'dictGet',
  ]

  ensurable do
    defaultvalues
    defaultto :present
  end

  def initialize(*args)
    super

    # Initialize the array as empty if called from `puppet resources` command
    if !self[:privileges] && provider.privileges != :absent
      self[:privileges] = []
    end

    # Forcibly munge any privilege with 'ALL' in the array to be replaced with a list
    # of ALL privileges as set by ClickHouse. This can't be done in the munge in the
    # property as that iterate over the array and there's no way to replace the entire
    # array before it's returned to the provider.
    if self[:ensure] == :present && self[:privileges].any? { |x| x.upcase == 'ALL' }
      self[:privileges] = $all_privileges.sort
    end
    # Sort the privileges array in order to ensure the comparision in the provider
    # self.instances method match.  Otherwise this causes it would keep resetting the
    # privileges.
    mangled = {}
    self[:privileges].each do |priv|
      # Remove trailing and leading spaces
      priv.strip!
      # INSERT and SELECT with columns specified
      if priv.include?('(')
        # Split between type and columns (if any)
        type, cols = priv.split(%r{\s+|\b}, 2)
        # Convert the type to uppercase
        type.upcase!
        # Remove parenthesis and spaces, then get an array of fields
        # by splitting them on the comma
        cols = cols.gsub(/\(|\)|\s*/,'').split(',') if cols
        # Create an array entry, if not exists, on the hash using the type as key
        mangled[type] = Array.new unless mangled[type]
        # Append columns, if any, to the key unless there is a key without
        # columns already present in the original privilege list.
        # This is to prevent mixing global privileges (eg. INSERT) with column-wise
        # ones (eg. INSERT(foo)) which will then result into resetting privileges.
        mangled[type].push(*cols) unless self[:privileges].include?(type)
      else
        priv.upcase!
        # Special case for dictGet privilege
        priv = 'dictGet' if priv == 'DICTGET'
        mangled[priv] = nil
      end
    end

    # Prepare proper privileges array
    self[:privileges] = mangled.sort.map do |k, v|
      str = k
      # Loop on elements with columns only
      unless v.nil? or v.empty?
        # Remove duplicate columns and sort
        flatten_cols = v.sort.uniq.join(', ')
        str += "(#{flatten_cols})"
      end
      str
    end.sort
  end

  validate do
    # The checks on provider.* are needed to make `puppet resources` happy
    if self[:ensure] == :present
      fail('`privileges` parameter is required') if Array(self[:privileges]).empty? && provider.privileges == :absent
      fail('`table` parameter is required') if self[:table].nil? && provider.table == :absent
      fail('`user` parameter is required') if self[:user].nil? && provider.user == :absent
      fail('`options` parameter requires a single value') if Array(self[:options]).count > 1
      if self[:table] =~ /\.\*$/ && Array(self[:privileges]).any? { |p| p =~ /^\s*?(INSERT|SELECT)\s*?\(\s*?.*\s*?\)/ }
        fail('columns cannot be specified in `privileges` parameter when using wildcard for tables')
      end
    end
    if self[:user] && self[:table]
      fail('`name` parameter must match user/table format.') if self[:name] != "#{self[:user]}/#{self[:table]}"
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the grant'
  end

  newparam(:distributed) do
    desc 'Execute queries using ON CLUSTER statement'
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:privileges, array_matching: :all) do
    desc 'User privileges'
    defaultto []

    validate do |value|
      fail('clickhouse_grant: `privileges` parameter value must be a String') unless value.is_a?(String)
      fail('clickhouse_grant: `privileges` parameter cannot be empty') if value.empty?
    end
  end

  newproperty(:options, array_matching: :all) do
    desc 'User options'
    defaultto 'NONE'

    validate do |value|
      fail('clickhouse_grant: `options` parameter value must be String') unless value.is_a?(String)
      fail('clickhouse_grant: `options` parameter must be one of: `GRANT`,`NONE`') unless ['GRANT','NONE'].include?(value.upcase)
    end

    munge do |value|
      value.upcase
    end
  end

  newproperty(:user) do
    desc 'User to apply grant(s) on'
  end

  newproperty(:table) do
    desc 'Table to apply privileges to'
  end

end
