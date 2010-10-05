#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.

require File.expand_path('../../../lib/hcard', __FILE__)

class Person
  include MongoMapper::Document
  include ROXML
  include Encryptor::Public

  xml_accessor :_id
  xml_accessor :diaspora_handle
  xml_accessor :url
  xml_accessor :profile, :as => Profile
  xml_reader :exported_key

  key :url,            String
  key :diaspora_handle, String, :unique => true
  key :serialized_public_key, String

  key :owner_id,  ObjectId

  one :profile, :class_name => 'Profile'
  many :albums, :class_name => 'Album', :foreign_key => :person_id
  belongs_to :owner, :class_name => 'User'

  timestamps!

  before_destroy :remove_all_traces
  before_validation :clean_url
  validates_presence_of :url, :profile, :serialized_public_key
  validates_format_of :url, :with =>
     /^(https?):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*(\.[a-z]{2,5})?(:[0-9]{1,5})?(\/.*)?$/ix

  def self.search(query)
    query = Regexp.escape( query.to_s.strip )
    Person.all('profile.first_name' => /^#{query}/i) | Person.all('profile.last_name' => /^#{query}/i)
  end

  def real_name
    "#{profile.first_name.to_s} #{profile.last_name.to_s}"
  end
  def owns?(post)
    self.id == post.person.id
  end

  def receive_url
    "#{self.url}receive/users/#{self.id}/"
  end

  def public_url
    "#{self.url}users/#{self.owner.username}/public"
  end


  def public_key_hash
    Base64.encode64 OpenSSL::Digest::SHA256.new(self.exported_key).to_s
  end

  def public_key
    OpenSSL::PKey::RSA.new( serialized_public_key )
  end

  def exported_key
    serialized_public_key
  end

  def exported_key= new_key
    raise "Don't change a key" if serialized_public_key
    @serialized_public_key = new_key
  end

  
  #webfinger methods
  def self.by_account_identifier(identifier)
    self.first(:diaspora_handle => identifier.gsub('acct:', '').to_s.downcase)
  end

  def self.local_by_account_identifier(identifier)
    person = self.by_account_identifier(identifier)
   (person.nil? || person.remote?) ? nil : person
  end

  def self.from_webfinger(identifier)
    local_person = self.by_account_identifier(identifier)
    if local_person
      Rails.logger.info("Do not need to webfinger, found a local person #{local_person.real_name}")
      return local_person
    end
    
    begin
      Rails.logger.info("Webfingering #{identifier}")
      profile = Webfinger.new(identifier)
    rescue Exception => e
      Rails.logger.info("no person found at: #{identifier}")
    end    
    self.build_from_webfinger(profile)
  end
  
  
  def self.build_from_webfinger(profile)
    return nil if profile.nil? || !profile.valid_diaspora_profile?
    new_person = Person.new
    new_person.exported_key = profile.public_key
    new_person.id = profile.guid
    new_person.diaspora_handle = profile.account
    new_person.url = profile.seed_location
    
    hcard = HCard.find profile.hcard
    new_person.profile = Profile.new(:first_name => hcard[:given_name], :last_name => hcard[:family_name])
    
    puts new_person.valid?
    new_person.save! ? new_person : nil
  end

  def remote?
    owner.nil?
  end

  def as_json(opts={})
    {
      :person => {
        :id           => self.id,
        :name         => self.real_name,
        :diaspora_handle        => self.diaspora_handle,
        :url          => self.url,
        :exported_key => exported_key
      }
    }
  end

  protected
  def clean_url
    self.url ||= "http://localhost:3000/" if self.class == User
    if self.url
      self.url = 'http://' + self.url unless self.url.match('http://' || 'https://')
      self.url = self.url + '/' if self.url[-1,1] != '/'
    end
  end

  private
  def remove_all_traces
    Post.all(:person_id => id).each{|p| p.delete}
    Album.all(:person_id => id).each{|p| p.delete}
  end
end
