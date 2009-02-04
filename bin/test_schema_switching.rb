# This script creates the cached disaccharide sequence from the
# disaccahrides generated from the glycomedb

require File.dirname(__FILE__) + '/script_common'

require 'app/models/disaccharide'

class MouseDisaccharide < Disaccharide
end

MouseDisaccharide.establish_connection
MouseDisaccharide.connection.schema_search_path = 'tax10090'
puts "#{MouseDisaccharide.find(:all).size}"
puts "#{Disaccharide.find(:all).size}"

