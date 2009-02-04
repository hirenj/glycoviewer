#!/usr/bin/env ruby

# This script checks the pathway coverage of structures

require File.join(File.dirname(__FILE__), 'script_common')

@reactions = Reaction.find_by_sql ["select * from reactions where pathway like ?","%hsa00512%"]

sugar_final = nil
# 
# @reactions.each { |reac|
#   begin
#     new_sugar = SugarHelper.CreateMultiSugar(reac.endstructure)
#     next unless new_sugar.root.name(:ic) == 'GalNAc'
#     if sugar_final == nil
#       sugar_final = new_sugar
#       next
#     end
#     sugar_final.union!(new_sugar)
#   rescue Exception => e
#     p e
#   end
# }
# 
# p sugar_final.sequence

sugar_final = SugarHelper.CreateMultiSugar('NeuAc(a2-3)Gal(b1-3)[GlcNAc(b1-3)][NeuAc(a2-6)][Gal(b1-4)GlcNAc(b1-6)]GalNAc',:ic)

SugarHelper.MakeRenderable(sugar_final)

File.open("Foobar.svg","w") {|file|
  SugarHelper.RenderSugar(sugar_final,:full,:boston,{ :padding => 200, :font_size => 50 }).write(file,4)
}