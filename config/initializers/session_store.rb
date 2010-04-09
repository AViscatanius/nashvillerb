# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_adva_cms_core_session',
  :secret      => '3d819b37bd9e47608de3c9d09a58d1b9b918b020160f05c970d9b9b4298c56adf9d1c36ffef797c15cf11916b9ab60c738b920a4767cf5095cc980a36975acd5'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
