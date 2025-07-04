class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false

# Tell Ahoy how to identify the current user
Ahoy.user_method = :true_user

# Enable API tracking for JavaScript tracking
Ahoy.api = true
