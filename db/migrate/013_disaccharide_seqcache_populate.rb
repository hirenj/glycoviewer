require 'SugarHelper'

class DisaccharideSeqcachePopulate < ActiveRecord::Migration
  def self.up
    Disaccharide.find(:all).each { |di|
      begin
        di_sugar = SugarHelper.CreateSugarFromDisaccharide(di)
        di.residuedelta = di_sugar.sequence
        di.save
      rescue Exception => e   
        p e     
      end      
    }    
  end

  def self.down
  end
end
