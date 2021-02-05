Puppet::Type.newtype(:clickhouse_role) do
  @doc = "Manage ROLEs in ClickHouse"

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

  newparam(:distributed) do
    desc 'Execute queries using ON CLUSTER statement'
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:profile) do
    desc "The settings profile name"
    defaultto :absent

    validate do |value|
      fail('clickhouse_role: `profile` parameter is required') if (value == :absent or value.strip.empty?) and provider.profile == :absent
      fail('clickhouse_role: `profile` parameter must be a String') unless value == :absent or value.is_a?(String)
    end
  end

end
