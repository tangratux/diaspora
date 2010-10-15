require File.join(Rails.root, 'lib/hcard')

class EMWebfinger
  TIMEOUT = 5
  def initialize(account)
    @account = account
    @callbacks = []
  end
  
  def fetch
     person = Person.by_account_identifier(@account)
      if person
        process_callbacks person
      else
        xrd
      end
  end

  def on_person(&block)
    @callbacks << block
  end

  private

  def xrd
    http = EventMachine::HttpRequest.new(xrd_url).get :timeout => TIMEOUT
    
    http.callback { get_webfinger_profile(webfinger_profile_url(http.response)) }

    http.errback { process_callbacks "there was an error getting the xrd at #{xrd_url}" }
  end


  def get_webfinger_profile(profile_url)
     http = EventMachine::HttpRequest.new(profile_url).get :timeout => TIMEOUT
     http.callback{ make_person_from_webfinger(http.response) }
     http.errback{ process_callbacks "failed to fetch webfinger profile for #{profile_url}"}
  end

  def make_person_from_webfinger(webfinger_profile)
    wf_profile = WebfingerProfile.new(@account, webfinger_profile)
    http = EventMachine::HttpRequest.new(wf _profile.hcard).get :timeout => TIMEOUT
    http.callback{
      hcard = HCard.build http.response
      p = Person.build_from_webfinger(wf_profile, hcard)
      process_callbacks(p)
    }
    http.errback{ process_callbacks "there was a problem fetching the hcard for #{@account}"}
  end


  def process_callbacks(person)
    @callbacks.each { |c| c.call(person) }
  end


  ##helpers
  #
  def webfinger_profile_url(xrd_response)
    doc = Nokogiri::XML::Document.parse(xrd_response)  
    swizzle @account, doc.at('Link[rel=lrdd]').attribute('template').value
  end

  def xrd_url(ssl = false)
    domain = @account.split('@')[1]
    "http#{'s' if ssl}://#{domain}/.well-known/host-meta"
  end
  
  def swizzle(account, template)
    template.gsub '{uri}', account
  end

end

class WebfingerProfile
  attr_accessor :webfinger_profile, :account, :links, :hcard, :guid, :public_key, :seed_location
  
  def initialize(account, webfinger_profile)
    @account = account
    @webfinger_profile = webfinger_profile
    @links = {}
    set_fields
  end
  
    def set_fields
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
end
