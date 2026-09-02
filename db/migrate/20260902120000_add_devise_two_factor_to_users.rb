class AddDeviseTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :text
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false
    add_column :users, :otp_backup_codes, :string, array: true, default: []
  end
end
