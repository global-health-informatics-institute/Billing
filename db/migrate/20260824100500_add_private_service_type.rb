class AddPrivateServiceType < ActiveRecord::Migration[6.0]
  def up
    return if ServiceType.where(name: 'Private', retired: false).exists?
    user = User.all.find { |u| u.is_superuser? } || User.first
    ServiceType.create!(
      name: 'Private',
      creator: user&.user_id || 1,
      retired: false
    )
  end

  def down
    ServiceType.where(name: 'Private').delete_all
  end
end
