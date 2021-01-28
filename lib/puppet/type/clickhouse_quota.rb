Puppet::Type.newtype(:clickhouse_quota) do
  @doc = "Manage user quotas in ClickHouse"

  autorequire(:clickhouse_user) { self[:user] }

  def initialize(*args)
    super

    settings = [
      self[:queries],
      self[:errors],
      self[:read_rows],
      self[:read_bytes],
      self[:result_rows],
      self[:result_bytes],
      self[:execution_time],
    ].join

    # If no setting is specified (no limit), interval duration has to be 0
    self[:duration] = 0 if settings.empty?

    # Calculate duration in seconds depending on the specified interval type
    if self[:duration] > 0 and self[:interval] != :second
      case self[:interval]
      when :minute
        self[:duration] *= 60
      when :hour
        self[:duration] *= 3600
      when :day
        self[:duration] *= 86400
      when :week
        self[:duration] *= 604800
      when :month
        self[:duration] *= 2628000
      when :quarter
        self[:duration] *= 7884000
      when :year
        self[:duration] *= 31536000
      end
    end
    # Sort user to match the ones reported by clickhouse
    self[:user] = Array(self[:user]).sort

    # Sort keys to match the ones reported by ClickHouse
    self[:keys] = Array(self[:keys]).sort
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

  newproperty(:duration) do
    desc "Quota duration for the type of interval specified"
    newvalue(/\d+/)
    defaultto 3600
  end

  newparam(:interval) do
    desc "Type of interval"
    newvalues(:second, :minute, :hour, :day, :week, :month, :quarter, :year)
    defaultto :second
  end

  newproperty(:randomized) do
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:keys, array_matching: :all) do
    desc "Keys specifies how the quota should be shared"
    newvalues(:user_name, :ip_address, :client_key, :none)
    defaultto :user_name
  end

  newproperty(:queries) do
    desc "Max queries number"
    newvalue(/\d+/)
  end

  newproperty(:errors) do
    desc "Max errors number"
    newvalue(/\d+/)
  end

  newproperty(:read_rows) do
    desc "Max read rows number"
    newvalue(/\d+/)
  end

  newproperty(:read_bytes) do
    desc "Max read rows bytes"
    newvalue(/\d+/)
  end

  newproperty(:result_rows) do
    desc "Max results rows number"
    newvalue(/\d+/)
  end

  newproperty(:result_bytes) do
    desc "Max results bytes"
    newvalue(/\d+/)
  end

  newproperty(:execution_time) do
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
