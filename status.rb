#!/usr/bin/ruby

require File.dirname(__FILE__) + "/karotz.rb"

begin
	k = Karotz.new
	k.pulse ARGV[0], ARGV[1].to_i
	(ARGV[3] == "false")? k.sad : k.happy
	k.say ARGV[2]
rescue => e
	puts e
end
exit 0
