FixtureBuilder.configure do |fbuilder|
    fbuilder.files_to_check += Dir['spec/factories.rb', 'spec/support/fixture_builder.rb']

    fbuilder.factory do
      @user    = Factory(:user)
      @aspect  = @user.aspect(:name => 'heroes') 
      @user2   = Factory(:user) 
      @aspect2 = @user2.aspect(:name => 'stuff') 
      @user3   = Factory(:user) 
      @aspect3 = @user3.aspect(:name => 'stuff')
    end
end
