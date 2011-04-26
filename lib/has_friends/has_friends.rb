module Has
  module Friends
    def self.included(base)
      base.extend Has::Friends::ClassMethods
    end
    
    module ClassMethods
      def has_friends
        include Has::Friends::InstanceMethods
        
        has_many :friendships
        has_many :friends, :through => :friendships, :source => :friend, :conditions => "friendships.status = 'accepted'"
        has_many :friendships_awaiting_acceptance, :conditions => "friendships.status = 'requested'", :class_name => 'Friendship', :foreign_key => :friend_id
        
        after_destroy :destroy_all_friendships
      end
    end
    
    module InstanceMethods
      def be_friends_with(friend, message = nil, relations = [])
        # no user object
        return nil, Friendship::STATUS_FRIEND_IS_REQUIRED unless friend
        
        # should not create friendship if user is trying to add himself
        return nil, Friendship::STATUS_IS_YOU if is?(friend)
        
        # should not create friendship if users are already friends
        return nil, Friendship::STATUS_ALREADY_FRIENDS if friends?(friend)
        
        # retrieve the friendship request
        friendship = self.friendship_for(friend)
        
        # let's check if user has already a friendship request or have removed
        request = friend.friendship_for(self)
        
        # friendship has already been requested
        return nil, Friendship::STATUS_ALREADY_REQUESTED if friendship && friendship.requested?
        
        # friendship is pending so accept it
        if friendship && friendship.pending?
          ActiveRecord::Base.transaction do
            friendship.accept!
            request.accept!
          end
          
          return friendship, Friendship::STATUS_FRIENDSHIP_ACCEPTED
        end
        
        ActiveRecord::Base.transaction do
          message = FriendshipMessage.create(:body => message) if message

          # we didn't find a friendship, so let's create one!
          friendship = self.friendships.create(:friend_id => friend.id, :status => 'requested', :message => message, :requested_at => Time.now)
          friendship.add_relations(relations)

          # we didn't find a friendship request, so let's create it!
          request = friend.friendships.create(:friend_id => id, :status => 'pending', :message => message, :requested_at => Time.now)
          request.add_relations(relations)
        end
        
        return friendship, Friendship::STATUS_REQUESTED
      end
      
      def friends?(friend)
        friendship = friendship_for(friend)
        !!(friendship && friendship.accepted?)
      end
      
      def friendship_for(friend)
        friendships.first :conditions => {:friend_id => friend.id}
      end
      
      def is?(friend)
        self.id == friend.id
      end
      
      def remove_friendship_with(friend)
        ActiveRecord::Base.transaction do
          [friendship_for(friend), friend.friendship_for(self)].compact.each do |friendship|
            friendship.destroy if friendship
          end
        end
      end
      
      def deny_friendship_with(friend)
        if (pendent = self.friendship_for(friend)).pending?
          ActiveRecord::Base.transaction do
            [friendship_for(friend), friend.friendship_for(self)].compact.each do |friendship|
              friendship.destroy if friendship
            end
          end
        else
          raise YouCanNotJudgeARequestFriendshipError
        end
      end
      
      def accept_friendship_with(friend, relations = nil)
        if (pendent = self.friendship_for(friend)).pending?
          requested = friend.friendship_for(self)
          
          ActiveRecord::Base.transaction do
            pendent.accept!(relations) 
            requested.accept! unless requested.accepted?
          end
        else
          raise YouCanNotJudgeARequestFriendshipError
        end
      end      
      
      private
        def destroy_all_friendships
          ActiveRecord::Base.transaction do
            Friendship.delete_all({:user_id => id})
            Friendship.delete_all({:friend_id => id})
          end
        end
    end
  end
end