# This script creates the cached disaccharide sequence from the
# disaccahrides generated from the glycomedb

require File.dirname(__FILE__) + '/script_common'

require 'app/models/disaccharide'

Disaccharide.find(:all).each { |di|
  begin
    di_sugar = SugarHelper.CreateSugarFromDisaccharide(di)
    di.residuedelta = di_sugar.sequence
    di.save
  rescue Exception => e   
    p e     
  end      
}