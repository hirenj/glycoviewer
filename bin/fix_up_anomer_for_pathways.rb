require File.dirname(__FILE__) + '/script_common'

require 'app/models/reaction'

reactions = Reaction.find_by_sql ["select * from reactions where pathway is not null "]

reactions.each { |reac|
  substr = reac.as_sugar(reac.substrate)
  endstr = reac.as_sugar(reac.endstructure)
  substr.root.anomer = 'u'
  endstr.root.anomer = 'u'
  reac.substrate = substr.sequence
  reac.endstructure = endstr.sequence
#  p substr.sequence
  reac.save
}