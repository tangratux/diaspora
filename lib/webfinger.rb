require 'fiber'
class Webfinger
#this class assumes where you are calling it from is wrapped in a fiber... if you are using rack fiber pool, you are  
  attr_accessor :webfinger_profile, :account, :links, :hcard, :guid, :public_key, :seed_location
  
  
  def initialize(account)
    @account = account
    @webfinger_profile = grab_webfinger_profile
    @links = {}
    set_helper_fields
  end
  
    
  def async_fetch(url)
    f = Fiber.current
    http = EventMachine::HttpRequest.new(url).get :timeout => 10 
    http.callback { f.resume(http) }
    http.errback  { f.resume(http) }
    return Fiber.yield
  end
  
  def set_helper_fields
    doc = Nokogiri::XML.parse(webfinger_profile)
    
    doc.css('Link').each do |l|  
      rel = l.attribute("rel").value
      href = l.attribute("href").value
      @links[rel] = href
      case rel
        when "http://microformats.org/profile/hcard"
          @hcard = href
        when "http://joindiaspora.com/guid"
          @guid = href     
        when "http://joindiaspora.com/seed_location"
          @seed_location = href
      end
    end
    
    if doc.at('Link[rel=diaspora-public-key]')
      begin
        pubkey = doc.at('Link[rel=diaspora-public-key]').attribute('href').value 
        @public_key = Base64.decode64 pubkey
      rescue Exception => e
        puts "probally not diaspora..."
      end
    end
  end
  
  def valid_diaspora_profile?
    !(@webfinger_profile.nil? || @account.nil? || @links.nil? || @hcard.nil? ||
        @guid.nil? || @public_key.nil? || @seed_location.nil? )
  end
  

  def grab_webfinger_profile
    domain = @account.split('@')[1] # the end of it 
    url = xrd_url(domain)
    xrd = async_fetch(url)
    webfinger = async_fetch(webfinger_profile_url(xrd.response))
    webfinger.response
  end
  
  
  #helpers
  def webfinger_profile_url(xrd_response)
    doc = Nokogiri::XML::Document.parse(xrd_response)  
    swizzle @account, doc.at('Link[rel=lrdd]').attribute('template').value
  end
  
  def xrd_url(domain, ssl = false)
    "http#{'s' if ssl}://#{domain}/.well-known/host-meta"
  end
  
  def swizzle(account, template)
    template.gsub '{uri}', account
  end
end