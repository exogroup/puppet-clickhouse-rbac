Puppet::Type.newtype(:clickhouse_user) do
  @doc = "Manage USERs in ClickHouse"

  # Require profile if specified
  autorequire(:clickhouse_profile) do
    self[:profile] if self[:profile]
  end

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the user'
  end

  newparam(:id) do
    desc 'The unique id of the user'
  end

  newparam(:distributed) do
    desc 'Execute queries using ON CLUSTER statement'
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:password_hash) do
    desc 'The password hash of the user. Use sha256() function to create it'
    defaultto ''
    newvalue(/^\w*$/)

    validate do |value|
      fail('clickhouse_user: `password_hash` parameter must be a String') unless
      fail('clickhouse_user: `password_hash` parameter must be valid SHA-256 hash') unless value =~ %r{^[a-fA-F0-9]{64}$|^$}
    end

    munge do |value|
      value.upcase
    end

    def change_to_s(currentvalue, _newvalue)
      'Created password' if currentvalue == :absent
      _newvalue.empty?? 'Removed password' : 'Changed password'
    end

    def is_to_s(_currentvalue)
      '[old password hash redacted]'
    end

    def should_to_s(_newvalue)
      '[new password hash redacted]'
    end
  end

  newproperty(:profile) do
    desc "The settings profile name"
    defaultto ''

    validate do |value|
      fail('clickhouse_user: `profile` parameter must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:host_ip, array_matching: :all) do
    desc "List of allowed host IPs for the user"
    defaultto '::/0'

    validate do |value|
      fail('clickhouse_user: `host_ip` parameter must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:host_names, array_matching: :all) do
    desc "List of allowed host names for the user"

    validate do |value|
      fail('clickhouse_user: `host_names` parameter must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:host_regexp, array_matching: :all) do
    desc "List of allowed host regexps for the user"

    validate do |value|
      fail('clickhouse_user: `host_regexp` parameter must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:host_like, array_matching: :all) do
    desc "List of allowed host LIKEs for the user"

    validate do |value|
      fail('clickhouse_user: `host_like` parameter must be a String') unless value.is_a?(String)
    end
  end

end
