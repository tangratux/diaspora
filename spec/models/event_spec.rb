#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe Event do
  let(:user1)   {Factory :user}
  let(:user2)   {Factory :user}
  let(:aspect1) {user1.aspect(:name => "Cats")}
  let(:aspect2) {user2.aspect(:name => "Dogs")}
  let(:event) { user1.build_post(:event, :title => "Party", :summary => "its going to be a good time",
                          :start_time => Time.parse("16 October 2010, 1:01 AM PDT"),
                          :end_time => Time.parse("16 October 2010, 3:01 AM PDT"), :to => aspect1.id) }

  it 'is valid' do
    event.should be_valid
  end

  it 'validates presence of a title' do
    event.title = nil
    event.should_not be_valid
  end

  it 'validates presence of a start time' do
    event.start_time = nil
    event.should_not be_valid
  end

  it 'validates presence of a end time' do
    event.end_time = nil
    event.should_not be_valid
  end
  
  it 'has many rsvps' do
    pending "how to do association checking with mongomapper, it gives a warning instead of failing"
    event.associations[:rsvp].type == :many
  end

  it 'is a post' do
    event.is_a?(Post).should be true
  end

  describe '#to_xml' do
    let(:doc) { event.to_xml }
    it 'has a title' do
      puts doc.to_s
      doc.at_xpath('./title').text.should == event.title
    end

    it 'has an summary' do
      doc.at_xpath('./summary').text.should == event.summary
    end


    it 'has an id' do
      doc.at_xpath('./_id').text.should == event.id.to_s
    end

    it 'has a start time' do
      doc.at_xpath('./start_time').text.should == event.start_time.to_s
    end

    it 'has a end time' do
      doc.at_xpath('./end_time').text.should == event.end_time.to_s
    end

    it 'includes the person' do
      doc.at_xpath('./person/_id').text.should == event.person.id.to_s
    end
  end

  context 'marshaing' do
    before do
      friend_users(user1, aspect1, user2, aspect2)
    end
    
    it 'receives the object has the same attributes' do
      xml = user1.salmon(event).xml_for(user2.person)
      event.delete
      user2.receive_salmon(xml)
      user2.reload
      received_event = user2.raw_visible_posts.first
      received_event.title.should == event.title
      received_event.summary.should == event.summary
      received_event.start_time.should == event.start_time
      received_event.end_time.should == event.end_time
    end
  end
end
