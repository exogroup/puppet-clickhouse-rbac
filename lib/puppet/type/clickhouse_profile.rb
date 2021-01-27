Puppet::Type.newtype(:clickhouse_profile) do
  @doc = "Manage Settings Profiles in ClickHouse"

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the profile'
  end

  newparam(:id) do
    desc 'The unique id of the profile'
  end

  newparam(:distributed) do
    desc 'Execute queries using ON CLUSTER statement'
    newvalues(:true, :false)
    defaultto :true
  end

  newproperty(:settings) do
    desc 'The setting profile settings'
    defaultto Hash.new

    validate do |value|
      if provider.settings == :absent
        fail('clickhouse_profile: `settings` hash cannot be empty') if (value.nil? or value.empty?)
        fail('clickhouse_profile: `settings` parameter must be a Hash') unless value.is_a?(Hash)
      end
    end

    munge do |hash|
      hash.each do |key,val|
        hash[key] = val.to_s
      end
    end
  end

end
