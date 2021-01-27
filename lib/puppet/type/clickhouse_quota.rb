Puppet::Type.newtype(:clickhouse_quota) do
  @doc = "Manage user quotas in ClickHouse"

  autorequire(:clickhouse_user) { self[:user] }

  def initialize(*args)
    super

    settings = [
      self[:max_queries],
      self[:max_errors],
      self[:max_read_rows],
      self[:max_read_bytes],
      self[:max_result_rows],
      self[:max_result_bytes],
      self[:max_execution_time],
    ].join

    # If no setting is specified, interval duration needs to be 0
    self[:interval] = 0 if settings.empty?

    # Sort user to match the ones reported by clickhouse
    self[:user] = Array(self[:user]).sort
  end

  validate do
    if self[:ensure] == :present
      fail('`user` parameter is required') if (self[:user].nil? or self[:user].empty?) and provider.user == :absent
      fail('`user` parameter cannot contain empty values') if Array(self[:user]).any? { |x| x.empty? }
    end
  end

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the quota'
  end

  newparam(:id) do
    desc 'The unique id of the quota'
  end

  newparam(:distributed) do
    desc 'Execute queries using ON CLUSTER statement'
    newvalues(:true, :false)
    defaultto :true
  end

  newproperty(:interval) do
    desc "Quota interval in seconds"
    newvalue(/\d+/)
    defaultto 3600
  end

  newproperty(:max_queries) do
    desc "Max queries number"
    newvalue(/\d+/)
  end

  newproperty(:max_errors) do
    desc "Max errors number"
    newvalue(/\d+/)
  end

  newproperty(:max_read_rows) do
    desc "Max read rows number"
    newvalue(/\d+/)
  end

  newproperty(:max_read_bytes) do
    desc "Max read rows bytes"
    newvalue(/\d+/)
  end

  newproperty(:max_result_rows) do
    desc "Max results rows number"
    newvalue(/\d+/)
  end

  newproperty(:max_result_bytes) do
    desc "Max results bytes"
    newvalue(/\d+/)
  end

  newproperty(:max_execution_time) do
    desc "Max execution time in seconds"
    newvalue(/\d+/)
  end

  newproperty(:user, array_matching: :all) do
    desc "User(s) to apply quota to"

    validate do |value|
      fail('clickhouse_quota: `user` parameter must be a String') unless value.is_a?(String)
    end
  end

end
