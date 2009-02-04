require 'soap/wsdlDriver'

class Enzymeinfo < ActiveRecord::Base
	belongs_to :geneinfo
	has_many :enzymeReaction
	validates_uniqueness_of :uprotid, :scope => :geneinfo_id, :if => Proc.new { |enzinfo| enzinfo.is_enzyme? && enzinfo.geneinfo.id != nil }
  validates_uniqueness_of :geneinfo_id, :scope => :record_class, :if => Proc.new { |enzinfo| enzinfo.is_gene? }
	validates_associated :geneinfo
	validates_presence_of :geneinfo

  before_validation :ensure_unique
    
	def ensure_unique
    #logger.error(geneinfo.methods.join(','))
    if geneinfo != nil
		  geneinfo.before_validation
	  else
	    return
    end
		if self.is_gene?
		  logger.error(self.geneinfo.id)
		  record = self.class.find(:first, :conditions => ["record_class='gene' and geneinfo_id = ?", self.geneinfo.id ])
  		if record != nil
  			@new_record = false
  			self.id = record.id
  		end		  
		  return
	  end
	  if self.is_enzyme?
		  record = self.class.find(:first, :conditions => ["uprotid = ? and geneinfo_id = ?", self.uprotid, self.geneinfo.id ] )
		  if record != nil
			  @new_record = false
			  self.id = record.id
		  end
	  end
	end
	
	def name
    return unless is_enzyme?
    if self.uprot_name != nil
      return self.uprot_name
    end
	  self.uprot_name = metadata.name
	  self.save
	  return self.uprot_name
  end

	def description
    return unless is_enzyme?
    if self.uprot_description != nil
      return self.uprot_description
    end
	  self.uprot_description = metadata.description
    self.save
    return self.uprot_description
  end

	def organism
    return unless is_enzyme?
    if self.uprot_organism != nil
      return self.uprot_organism
    end
    self.uprot_organism = metadata.orgS
    self.save
    return self.uprot_organism
  end
	
	def is_enzyme?
	  return self.record_class.to_sym == :enzyme 
	end

	def is_context?
	  return self.record_class.to_sym == :context
	end

	def is_gene?
	  return self.record_class.to_sym == :gene
	end
	
	def enzyme_reactions
	  EnzymeReaction.find_all_by_enzymeinfo_id(self)
  end

  def has_reaction?
    enzyme_reactions.size > 0
  end

	private

	def metadata
    return unless is_enzyme?
	  return @metadata unless @metadata == nil
    wsdl_url = 'http://genome.dkfz-heidelberg.de/menu/hobit/2005/04/SoapDB.wsdl'
    soap = SOAP::WSDLDriverFactory.new( wsdl_url ).createDriver
    @metadata = soap.srsEntryXml("[SWISSPROT-acc:#{uprotid}]").swissEntry
    return @metadata
  end
	
end
