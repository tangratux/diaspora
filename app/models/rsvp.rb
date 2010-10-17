#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Rsvp
  include MongoMapper::EmbeddedDocument
  include ROXML
  include Diaspora::Webhooks
  include Encryptable
  #include Diaspora::Socketable

  xml_reader :event_id
  xml_reader :status
  xml_reader :person_handle

  key :event_id,  ObjectId
  key :person_id, ObjectId
  key :status,    Integer

  belongs_to :person, :class_name => "Person"

  validates_presence_of :status, :person_id

  def person_handle
    self.person.diaspora_handle
  end

  def person_handle= handle
    self.person = Person.by_webfinger(handle)
  end

  def event_id
    self._parent_document.id
  end

  def event
    self._parent_document
  end

  #ENCRYPTION

  xml_accessor :creator_signature
  xml_accessor :post_creator_signature

  key :creator_signature, String
  key :post_creator_signature, String

  def signable_accessors
    accessors = self.class.roxml_attrs.collect{|definition|
      definition.accessor}
    accessors.delete 'person'
    accessors.delete 'creator_signature'
    accessors.delete 'post_creator_signature'
    accessors
  end

  def signable_string
    signable_accessors.collect{|accessor|
      (self.send accessor.to_sym).to_s}.join ';'
  end

  def verify_post_creator_signature
    verify_signature(post_creator_signature, post.person)
  end

  def signature_valid?
    verify_signature(creator_signature, person)
  end

end
