# clickhouse.rb
# Provide facts relative to current clickhouse node

if Facter::Core::Execution.which('clickhouse-server')
  Facter.add(:clickhouse_version) do
    setcode do
      output = Facter::Core::Execution.execute('clickhouse-server --version 2>/dev/null')
      $1 if output =~ /version ([^\s]+)/
    end
  end
end

# Restrict fact to clickhouse-client executable presence
if !Facter::Core::Execution.which('clickhouse-client')
  return
end

require 'json'

def query(sql, json=true)
  begin
    sql_formatted = sql.gsub(/\s+|\n/,' ').strip
    cmd = "clickhouse-client --log_queries 0 -q '#{sql_formatted}'"
    cmd << ' --format JSON' if json
    cmd << ' 2>/dev/null'
    result = Facter::Core::Execution.execute(cmd)
    if json
      rows = JSON.parse(result)
      rows['data'].count == 1 ? rows['data'].first : rows['data']
    else
      rows = result.split("\n")
      rows.count == 1 ? rows.first : rows
    end
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

$info = query(sql)
$info.each do |key, val|
  val = val.to_s.strip
  next if val.empty?
  Facter.add("clickhouse_#{key}".to_sym) do
    setcode do
      val
    end
  end
end