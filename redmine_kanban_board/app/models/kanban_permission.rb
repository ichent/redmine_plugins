class KanbanPermission < ActiveRecord::Base
  belongs_to :user

  # Check a user permissions
  def self.allowed_to?(action, user)
    if User.current.admin?
      return true
    end

    user_permissions = KanbanPermission.find(:first, :conditions => ['user_id = ?', user.id.to_i])

    unless user_permissions.blank?
      if user_permissions[action].to_i == 1
        return true
      else
        return false
      end
    else
      return false
    end
  end
end
