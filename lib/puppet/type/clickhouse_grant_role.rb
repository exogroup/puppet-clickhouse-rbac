Puppet::Type.newtype(:clickhouse_grant_role) do
  @doc = "Manage role grants in ClickHouse"

  autorequire(:clickhouse_user) { self[:user] }
  autorequire(:clickhouse_role) { self[:name] }

  def initialize(*args)
    super

    # Sort the users array to match what reported by CH
    self[:user] = Array(self[:user]).sort
  end

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the grant'
  end

  newparam(:distributed) do
    desc 'Execute queries using ON CLUSTER statement'
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:user, array_matching: :all) do
    desc 'User(s) to apply the role to'
    defaultto :absent

    validate do |value|
      fail("clickhouse_grant_role: `user` parameter requires a value") if (value == :absent or value.strip.empty?) and provider.user == :absent
      fail("clickhouse_grant_role: `user` parameter must be a String") unless value == :absent or value.is_a?(String)
    end
  end

end
