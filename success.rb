require './karotz.rb'

k = Karotz.new

k.say ARGV[0] || "Say what?!"
k.pulse :green, 10


