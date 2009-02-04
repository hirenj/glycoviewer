# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '1.2.6'


# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

$LOAD_PATH.unshift(File.join(Rails.root, 'SugarCoreRuby/lib'))

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.action_controller.session = { :session_key => "_myapp_session", :secret => "some secret phrase of at least 30 characters" }

  config.gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate', 
    :source => 'http://gems.github.com'

end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below


require 'DebugLog'
DebugLog.global_logger = Logger.new("#{Rails.root}/log/#{RAILS_ENV}.log")


# Trigger init of the residues
require 'SugarHelper'

# -1 = full logging
# 5 = no logging
DebugLog.log_level(-1)

# Mime::Type.register "application/xml", :xml
# Mime::Type.register "text/xml", :xml
Mime::Type.register "application/xhtml+xml", :xhtml


# register a new Mime::Type
Mime::SVG = Mime::Type.new 'image/svg+xml', :svg
Mime::EXTENSION_LOOKUP['svg'] = Mime::SVG
Mime::LOOKUP['image/svg+xml'] = Mime::SVG
Mime::SET << Mime::SVG

Mime::PNG = Mime::Type.new 'image/png', :png
Mime::EXTENSION_LOOKUP['png'] = Mime::PNG
Mime::LOOKUP['image/png'] = Mime::PNG
Mime::SET << Mime::PNG

Mime::TXT = Mime::Type.new 'text/plain', :txt
Mime::EXTENSION_LOOKUP['txt'] = Mime::TXT
Mime::LOOKUP['text/plain'] = Mime::TXT
Mime::SET << Mime::TXT

class String
  def is_numeric?
    Float self rescue false
  end
end
