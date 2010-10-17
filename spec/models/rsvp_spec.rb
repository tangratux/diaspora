#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe Rsvp do
  let(:user1)   {Factory :user}
  let(:user2)   {Factory :user}
  let(:aspect1) {user1.aspect(:name => "Cats")}
  let(:aspect2) {user2.aspect(:name => "Dogs")}
  let(:event)   {user1.post(:event, :title => "Party", :summary => "its going to be a good time",
                            :start_time => DateTime.parse("16 October 2010, 1:01 AM PDT"),
                            :end_time => DateTime.parse("16 October 2010, 3:01 AM PDT"), :to => aspect1.id) }

  let(:user3)   {Factory :user}
  let(:aspect3) {user3.aspect(:name => "Bats")}

  before do
    friend_users(user1, aspect1, user2, aspect2)
    friend_users(user1, aspect1, user3, aspect3)
    user2.receive_salmon(user1.salmon(event).xml_for(user2.person))
    user3.receive_salmon(user1.salmon(event).xml_for(user3.person))
  end

  let(:rsvp) {user2.rsvp_for(:event => event, :attending => YES)}

  it 'is valid' do
    rsvp.should be_valid
  end

  it 'validates presence of status' do
    rsvp.status = nil
    rsvp.should_not be_valid
  end

  it 'validates persence of person_id' do
    rsvp.person = nil
    rsvp.should_not be_valid
  end

  it 'has event as parent' do
    rsvp.event.should be event
  end

  describe '#to_xml' do
    let(:doc) { rsvp.to_xml }

    it 'has event_id' do
      doc.at_xpath('./event_id').text.should == rsvp.event.id.to_s
    end

    it 'has a status' do
      doc.at_xpath('./status').text.should == rsvp.status.to_s
    end

    it 'has an person handle' do
      puts doc.to_xml
      doc.at_xpath('./person_handle').text.should == rsvp.person.diaspora_handle
    end
  end

  

  context 'user RSVPing to an event' do

    it 'should add the RSVP to the event' do
      event.reload
      event.rsvps.include?(rsvp).should be true 
    end

    it 'sends out the RSVP' do
      user2.should_receive(:send_rsvp).once
      rsvp
    end

    it 'requires awareness of the event' do
      event2 = user1.post(:event, :title => "Party", :summary => "its going to be a good time",
                          :start_time => DateTime.parse("16 October 2010, 1:01 AM PDT"),
                          :end_time => DateTime.parse("16 October 2010, 3:01 AM PDT"), :to => aspect1.id) 
      user2.reload
      user2.raw_visible_posts.include?(event2).should be false
      proc{ user2.rsvp_for(:event => event2, :attending => YES) }.should raise_error /Cannot RSVP to an event you don't know about/
    end

    it 'requires a status' do
      proc{ user2.rsvp_for(:event => event) }.should raise_error /Must include attending status/
    end
  end

  describe '#send_rsvp' do
    it 'should send the rsvp upstream' do
      user2.should_receive(:push_to_people) {|post, people| post.is_a?(Rsvp).should be true; people.size.should be 1}
      rsvp
    end

    it 'should dispactch the rsvp downstream' do
      user1.should_receive(:push_to_people) {|post, people| people.include?(user3).should be true}
      user1.receive_salmon(user2.salmon(rsvp).xml_for(user1.person))
    end

  end
end
