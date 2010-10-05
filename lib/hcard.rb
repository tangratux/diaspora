#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.

require 'fiber'

module HCard
  
  def self.async_fetch(url)
    f = Fiber.current
    http = EventMachine::HttpRequest.new(url).get :timeout => 10

    http.callback { f.resume(http) }
    http.errback  { f.resume(http) }

    return Fiber.yield
  end
  
  def self.find url
    doc = Nokogiri::HTML(HCard::async_fetch(url).response)
    {
      :given_name => doc.css(".given_name").text,
      :family_name => doc.css(".family_name").text,
      :url => doc.css("#pod_location").text
    }
  end
end
