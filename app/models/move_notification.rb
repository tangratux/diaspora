#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class MoveNotification
  include ROXML
  include Diaspora::Webhooks

  xml_name :move_notification
  xml_reader :old_handle
  xml_reader :new_handle

  attr_accessor :old_handle, :new_handle
  

  def self.make(opts = {})
    notification = MoveNotification.new
    notification.old_handle = opts[:old_handle]
    notification.new_handle = opts[:new_handle]
    notification
  end

  def perform
    Person.update_by_webfinger(old_handle, new_handle)
  end

end
