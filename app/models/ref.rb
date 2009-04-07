class Ref < ActiveRecord::Base
	belongs_to :enzymeReaction
	def desc
	  @desc || ''
  end
end
