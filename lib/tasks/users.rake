# frozen_string_literal: true

namespace :users do
  desc "Set a password for a specific user"
  task :set_password, [:email, :password] => :environment do |_t, args|
    email = args[:email]
    password = args[:password]

    if email.blank? || password.blank?
      puts "Usage: rake users:set_password[email@example.com,newpassword]"
      exit 1
    end

    user = User.find_by(email: email)
    if user.nil?
      puts "User with email #{email} not found"
      exit 1
    end

    user.password = password
    user.password_confirmation = password
    if user.save
      puts "Password successfully set for #{email}"
    else
      puts "Error setting password: #{user.errors.full_messages.join(', ')}"
      exit 1
    end
  end

  desc "Set a temporary password for all users without a password"
  task set_temporary_passwords: :environment do
    default_password = ENV.fetch("DEFAULT_PASSWORD", "ChangeMe123!")
    updated_count = 0

    User.find_each do |user|
      # Check if user has a valid password (encrypted_password should not be blank)
      if user.encrypted_password.blank?
        user.password = default_password
        user.password_confirmation = default_password
        if user.save
          updated_count += 1
          puts "Set temporary password for #{user.email}"
        else
          puts "Error setting password for #{user.email}: #{user.errors.full_messages.join(', ')}"
        end
      end
    end

    puts "\nUpdated #{updated_count} user(s) with temporary password: #{default_password}"
    puts "Users should change their password on first login."
  end
end

