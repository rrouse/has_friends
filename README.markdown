has_friends
===========

**ATTENTION:** This is a Rails 3 implementation.

NOTE: You should have a User model. When you execute the plugin generator, I'll add a column
friends_count on users' table.


Instalation
-----------

1) Add a gem line to your Gemfile. `gem 'has_friends-rails3', :require => 'has_friends'`

2) Execute the plugin generator `rails g has_friends:migration`

3) Run the migrations with `rake db:migrate`

Usage
-----

1) Add the method call `has_friends` to your model.

	class User < ActiveRecord::Base
	  has_friends
	end

	john = User.find_by_login 'john'
	mary = User.find_by_login 'mary'
	paul = User.find_by_login 'paul'

	# John wants to be friend with Mary
	# always return a friendship object
	john.be_friends_with(mary, "Hi Mary! I have worked with you on Meroy Merlin!")
	
	# Creating a new Relation kind
	RelationType.create(:name => "coworker")
	
	# You can pass kind of relationship, when...
	john.be_friends_with(mary, "Hi Mary! I have worked with you on Meroy Merlin!", [:coworker])

	# if you specify a non existent Relation, 
	# it will create a new Relation
	# and associate then to friendship 
	john.be_friends_with(mary, "Hi Mary! I have worked with you on Meroy Merlin!", [:coworker, :friend])
	# In this case, friend is a new relation

	# are they friends?
	john.friends?(mary) ==> false

	# get the friendship object
	john.friendship_for(mary)
	
	# Mary accepts John's request if it exists...
	mary.accept_friendship_with(john)
	mary.friends?(john) ==> true
	
	# either if Mary request John's friendship, then they will be friends automatically.
	mary.be_friends_with(john)
	mary.friends?(john) ==> true
	
	# Mary can reject John's friendship.
	mary.remove_friendship_with(john)
	
	# check if an user is the current user, so it can
	# be differently presented
	mary.friends.each {|friend| friend.is?(current_user) }

	# if you're dealing with a friendship object,
	# the following methods are available
	friendship.accept!
	
	# You can specify relations when accept a friendship, so...
	friendship.accept!([:friend])
	
	# If you want to accept friendship and clear current relations...
	friendship.accept!([])
	
	# the be_friends_with method returns 2 params: friendship object and status.
	# the friendship object will be present only when the friendship is created
	# (that is, when is requested for the first time)
	# STATUS_ALREADY_FRIENDS       # => users are already friends
	# STATUS_ALREADY_REQUESTED     # => user has already requested friendship
	# STATUS_IS_YOU                # => user is trying add himself as friend
	# STATUS_FRIEND_IS_REQUIRED    # => friend argument is missing
	# STATUS_FRIENDSHIP_ACCEPTED   # => friendship has been accepted
	# STATUS_REQUESTED             # => friendship has been requested
	
	friendship, status = mary.be_friends_with(john)
	
	if status == Friendship::STATUS_REQUESTED
	  # the friendship has been requested
	  Mailer.deliver_friendship_request(friendship)
	elsif status == Friendship::STATUS_ALREADY_FRIENDS
	  # they're already friends
	else
	  # ...
	end


LICENSE:
--------

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.