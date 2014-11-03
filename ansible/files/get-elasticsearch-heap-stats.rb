#!/usr/bin/env ruby

# Usage:
# for x in search-node1 search-node2 search-node3 search-node4 search-node5 search-node6;
# do echo $x; ssh $x "fgrep -h monitor.jvm /var/log/elasticsearch/dpla-elasticsearch.log*" | sort | ~/get-heap-stats.rb > /tmp/$x-heapstats.tab;
# done


SEPARATOR = "\t"

if $stdin.tty?
  $stderr.puts "Error: ElasticSearch logfile(s) must be supplied via stdin"
  $stderr.puts "Usage: cat *.log | #{$0} "
  exit 1
end

# Input strings look like:
# [2013-12-04 08:58:06,066][INFO ][monitor.jvm              ] [search-node1] [gc][ConcurrentMarkSweep][551815][4] duration [7.7s], collections [1]/[7.9s], total [7.7s]/[7.8s], memory [11.1gb]->[11.5gb]/[12.3gb], [snip...]

lines = []
$stdin.each_line do |line|
  next unless line =~ /monitor\.jvm/

  if line.match /^\[(.+?)\].* memory \[(.+?)\]->\[(.+?)\]\/\[(.+?)\]/
    lines << [$1, $2, $3, $4].join(SEPARATOR).gsub('gb', '')
  end
end

puts %w( Time, Old, New, Max ).join(SEPARATOR)
puts lines.sort.join("\n")