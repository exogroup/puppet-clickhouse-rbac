# Provide facts relative to current clickhouse node

# Prevent fact to return if clickhouse-server service is disabled
if Facter.value(:service_provider) == 'systemd'
  output = Facter::Core::Execution.execute('systemctl is-enabled clickhouse-server 2>/dev/null')
  return unless output.match?(/enabled/)
end

# Retrieve clickhouse-server version
if Facter::Core::Execution.which('clickhouse-server')
  Facter.add(:clickhouse_version) do
    setcode do
      output = Facter::Core::Execution.execute('clickhouse-server --version 2>/dev/null')
      $1 if output =~ /version (\d+\.\d+\.\d+\.\d+)/
    end
  end
end

# Prevent fact to return if clickhouse-client executable is not available
return unless Facter::Core::Execution.which('clickhouse-client')

require 'json'

def query(sql)
  begin
    sql_formatted = sql.gsub(/\s+|\n/,' ').strip
    cmd = "clickhouse-client --log_queries 0 -q '#{sql_formatted}' --format JSON 2>/dev/null"
    result = Facter::Core::Execution.execute(cmd)
    rows = JSON.parse(result)
    rows['data']
  rescue
    Hash.new
  end
end

sql = (<<~SQL)
  SELECT
    cluster AS cluster_name,
    replica_num,
    shard_num
  FROM system.clusters
  WHERE is_local = 1
SQL

# Prevent fact to return if query doesn't return any value
return unless data = query(sql).first

# Create fact for each column returned by the query
data.each do |key, val|
  val = val.to_s.strip
  next if val.empty?
  fact = "clickhouse_#{key}".to_sym
  Facter.add(fact) { setcode { val } }
end
