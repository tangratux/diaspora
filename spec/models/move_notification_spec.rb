#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe MoveNotification do
  
  let(:user1) {Factory.create :user}
  let(:user2) {Factory.create :user}

  let(:aspect1) {user1.aspect(:name => "guys")}
  let(:aspect2) {user2.aspect(:name => "girls")}

  let(:old_handle) {user1.diaspora_handle}
  let(:new_handle) {"cats@example.com"}
  
  let(:notification) {MoveNotification.make(:old_handle => old_handle, :new_handle => new_handle)}

  before do
    friend_users(user1, aspect1, user2, aspect2)
  end

  context 'sending a notification' do
    context 'first update to a pod' do

      it 'should update the persons diaspora handle' do
        xml = user1.salmon(notification).xml_for(user2.person)
        person = user1.person
        user1.delete
        user2.receive_salmon(xml)

        person.reload
        person.diaspora_handle.should == new_handle
      end

      it 'should update the person by webfinger' do
        Person.should_receive(:update_by_webfinger).with(old_handle, new_handle)

        xml = user1.salmon(notification).xml_for(user2.person)
        person = user1.person
        user1.delete
        user2.receive_salmon(xml)
      end

    end
  end

  
end
