#!/usr/bin/env ruby 
require 'io/console' # to parse console input
require 'couchrest'
require 'json'
require 'ruby-progressbar'

if ARGV.length != 3
  puts './couchdb_restore.db http://username:password@couchdbhost:5984/target_database source_dump.json'
  exit 64
end

$target_URL = ARGV[0]
$source_json_file = ARGV[1]

puts "You're about to upload content from #{$source_json_file} to #{$target_dbname}@#{$target_host}"
puts "Press Enter if you agree or anyother key to exit"
$continue = STDIN.getch

# puts '->'+$continue.ord.to_s+'<-' # convert to ASCII number

if $continue.ord != 13 # CR ASCII number
  puts "OK, maybe another time.."
  exit 1
elsif not File.exists? $source_json_file or not File.readable? $source_json_file
  puts "#{$source_json_file} doesn't exists or I can't read it..please check it"
  exit 1
end

$header = ''
$buffer_size = 0
$buffer_limit = 250
$buffer = []

puts "** #{$target_URL} **"

db = CouchRest.database $target_URL

$total_lines = nil
progressbar = ProgressBar.create(:title => "Restoring to #{$target_URL}", :total => $total_lines, :format => '%t |%w| %c/%C (%a - %E)')

IO.foreach $source_json_file do |line|
  $line_str = line.chomp
  # puts "line_str ->#{$line_str}<-"
  if not $line_str.nil? and not $line_str.empty?
    # {"total_rows":587,"offset":0,"rows":[
    if /^\{"id":"/.match($line_str)
      $line_str.gsub!(/,\s*$/,'')
      $parsed_json = JSON.parse($line_str)["doc"]
      $parsed_json.delete '_rev'
      $buffer.push $parsed_json
      if $buffer.length == $buffer_limit
        #puts db.bulk_save($buffer)
        db.bulk_save($buffer)
        progressbar.progress += $buffer.length
        $buffer = []
      end
    elsif /^\{"total_rows":(\d+),/.match($line_str)
        $total_lines = $1.to_i
        $full_header = $line_str
        progressbar.log "** Dump header found --> #{$full_header.chomp} **"
        progressbar.total = $total_lines
    end
  end
end

if $buffer.length != 0
  #puts db.bulk_save($buffer)
  db.bulk_save($buffer)
  progressbar.progress = $total_lines
  $buffer = []
end

progressbar.finish
