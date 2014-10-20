#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require 'resolv'

EXIT_CODES = {
  :unknown => 3,
  :critical => 2,
  :warning => 1,
  :ok => 0
}

options =
{
  :debug => false,
  :domains => []
}

opt_parser = OptionParser.new do |opt|

  opt.on("--domains domain,[domain]","which domains do you wish to report on?") do |domains|
    options[:domains] = domains.split(',')
  end

  opt.on("--debug","enable debug mode") do
    options[:debug] = true
  end

  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!

raise OptionParser::MissingArgument, 'Missing "--domains"' if (options[:domains].empty?)

if (options[:debug])
  puts 'Options: '+options.inspect
end

begin

record_variants = {}

options[:domains].each do |domain|

  txt = Resolv::DNS.open do |dns|

    records = dns.getresources(domain, Resolv::DNS::Resource::IN::TXT)
    if (records.empty?)
      (record_variants["record missing"] ||= []) << domain
      puts "no TXT records for #{domain}" if (options[:debug])
      next
    end

    txt_strings = []

    records.each do |record|
      txt_strings.concat record.strings
    end

    spf_record_n = txt_strings.index{|s| s.downcase.include?'spf1'}

    if (!spf_record_n)
      puts "no spf record for #{domain}" if (options[:debug])
      (record_variants["record missing"] ||= []) << domain
      next
    end

    spf_record = txt_strings[spf_record_n]

    (record_variants[spf_record] ||= []) << domain

    puts "record for #{domain}: #{spf_record}" if (options[:debug])


  end

  if (record_variants.length > 1)
    puts 'CRIT: Multiple variants of the SPF record:'
    record_variants.each do |record, domains|
      puts record + ': ' + domains.join(',')
    end

    exit EXIT_CODES[:critical]
  end

end

rescue SystemExit
  raise
rescue Exception => e
  puts 'CRIT: Unexpected error: ' + e.message + ' <' + e.backtrace[0] + '>'
  exit EXIT_CODES[:critical]
end


puts 'OK: All records in sync.'
exit EXIT_CODES[:ok]

