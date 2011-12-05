require 'addressable/uri'
require 'base64'
require 'hmac-sha1'
require 'open-uri'
require 'nokogiri'
require 'fileutils'

API = "http://api.karotz.com/api/karotz/"
IID_STORE = ".interactiveid"

APIKEY= 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX'
SECRET= 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX'
INSTALLID = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX'

class Karotz

  def initialize
    @iid = (File.exist? IID_STORE)? open(IID_STORE).read : "9"
    begin
	config()
	puts "config went well?"
        return
    rescue
        puts "interactiveid is probably bad or stale"
    	FileUtils.rm IID_STORE if File.exists? IID_STORE
	start()
    end
  end

  COLORS = {
    :blue => '0000FF',
    :red => 'FF0000',
    :green => '00FF00',
    :yellow => 'FFFF00'
  }

  def start()
    puts "starting new session"
    parameters = {
      'installid' => INSTALLID,
      'apikey' => APIKEY,
      'once' => (rand(9999999) + 1000000).to_s,
      'timestamp' => Time.now.to_i.to_s
    }
    query = sign(parameters, SECRET)
    q = "#{API}start?#{query}"
    begin
    	msg = Nokogiri::XML(open(q))
        @iid = msg.css('VoosMsg interactiveMode interactiveId').first.content
        save()
    rescue
	stop()
        start() #recursion...
    end
    @iid
  end

  def say(text) 
    speech = text || "Whatever"
    voos = api('tts', {
      :action => 'speak',
      :lang => 'EN',
      :text => speech
    })
  end

  def pulse(color, seconds = nil) 
    hex = COLORS[color] || color
    time = seconds || 3
    voos = api('led', {
      :action => 'pulse',
      :color => hex,
      :pulse => time * 1000,
      :period => 500
    })
  end

  def sad
    voos = api('ears', {
	:left => 90,
        :right => 90,
        :relative => 'false'
   })
  end

  def happy 
    voos = api('ears', {
	:left => 0,
        :right => 0,
        :relative => 'false'
   })
  end

  def config
    voos = api('config', {})
  end

  def stop()
    puts "ending interaction" 
    voos = api('interactivemode', {
      :action => 'stop'
    })
    FileUtils.rm IID_STORE
  end

  private

  def save()
    open(IID_STORE, "w") do |io|
      io.write @iid
    end
  end

  # sign parameters in alphabetical order according to 
  # dev.karotz.com
  def sign(p, signature)
      sorted = Hash[p.sort]
      url = Addressable::URI.new
      url.query_values = sorted
      #puts url.query
      signed = Base64.encode64((HMAC::SHA1.new(signature) << url.query).digest).strip
      sorted['signature'] = signed
      url.query_values = sorted
      url.query
  end

  def api(function, options) 
    options.each { |k, v| options[k] = v.to_s }
    options['interactiveid'] = @iid.to_s
    uri = Addressable::URI.new
    uri.query_values = options
    q = "#{API}#{function}?#{uri.query}"
    puts q
  #  begin
      msg = Nokogiri::XML(open(q))
      puts msg
      msg
      sleep(2)
   # rescue => e
   #   puts "API call failed: #{e}"
   # end
  end
end

# testmsg = '''
# <VoosMsg>
# <id>75d2b1e5-7550-4428-90b6-717792561e13</id>
# <interactiveMode>
#   <action>START</action>
#   <interactiveId>d1f80b5f-813c-4f27-929a-31ce198a8bba</interactiveId>
# </interactiveMode>
# </VoosMsg>
# '''

#k = Karotz.new
#k.happy
#k.start
#k.say "cucumber #232 (broken since build #170)"
#k.pulse :red, 10
#k.pulse :blue, 1
#k.say "Thats better"
#sleep(10)
#k.stop

#stop(interactiveid)

