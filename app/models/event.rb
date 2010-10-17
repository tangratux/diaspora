#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Event < Post

  xml_reader :title
  xml_reader :summary
  xml_reader :start_time
  xml_reader :end_time

  key :title,      String
  key :summary,    String
  key :start_time, Time
  key :end_time,   Time

  
  many :rsvps, :class_name => 'Rsvp'
  
  validates_presence_of :title, :start_time, :end_time

  timestamps!

end
