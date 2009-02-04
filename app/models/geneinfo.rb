require 'rexml/document'
require 'net/http'
require 'uri'

class Geneinfo < ActiveRecord::Base
	has_many :enzymeinfo
	validates_uniqueness_of :genename

	before_validation :ensure_unique
	
	def ensure_unique
		record = self.class.find(:first, :conditions => ["genename = ?", genename] )
		if record != nil
			@new_record = false
			self.id = record.id
		end
		
	end
	
	def all_uprot_ids
    wsdl_url = 'http://genome.dkfz-heidelberg.de/menu/hobit/2005/04/SoapDB.wsdl'
    soap = SOAP::WSDLDriverFactory.new( wsdl_url ).createDriver
    begin
      result = soap.srsEntryXml("[SWISSPROT-gen:#{genename}]")      
      result = [ result.swissEntry ].flatten
    rescue SOAP::FaultError => e
      if (e.detail.hobitStatuscode.statuscode == '700')
        result = []
      else
        raise Exception.new('Error retrieving data from UNIPROT')
      end
    end
	  return result.collect { |res| res.primAcc }
	end
	
	def populate_uprot_ids
	  all_uprot_ids.each { |uprot|
	    enzyme = Enzymeinfo.new(:uprotid => uprot, :geneinfo => self, :record_class => :enzyme.to_s)
	    enzyme.save
	  }
  end

  def self.easyfind(argHash)
      fieldnames = argHash[:fieldnames]
      keywords = argHash[:keywords]
      order = argHash[:order]
      incl = argHash[:include]
      unless keywords.empty?
          keywordArray = []
          theSqlArray = keywords.inject([]) do |agg, keyword| 
              aLineArray = fieldnames.inject([]) {|lineSectionsArray, aFieldname| 
                      keywordArray << "%#{keyword.downcase}%"
                      lineSectionsArray << 'LOWER('+aFieldname+')' + " LIKE ?" 
                  }
              aLine = aLineArray.join(" OR ")
              aLine = "(" + aLine + ")" 
              agg << aLine
          end
          theSql = theSqlArray.join(" AND ")
          logger.error(theSql)
          result = self.find(:all, :conditions => [theSql] + keywordArray, :order => order, :include => incl)
      else
          result = []
      end
      return result
  end

  def populate
    logger.error("Synonyms are #{self.synonyms.empty?}")
    if self.geneid == nil
      return
    end
    logger.error("Pulling out all the aliases")
    self.synonyms = XPath.match(metadata, "//Gene-ref_syn_E").collect { |node| node.text }.join(',')
    mim_metadata = XPath.match(metadata, "//Dbtag[Dbtag_db='MIM']/Dbtag_tag/Object-id/Object-id_id").first 
    if mim_metadata != nil 
      self.mimid = mim_metadata.text
    end
    self.save
    return
  end


  private

	def metadata
	  return @metadata unless @metadata == nil
    rest_url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&retmode=xml&id='
    xmlblob = Net::HTTP.get(URI.parse(rest_url+geneid.to_s))
    @metadata = Document.new(xmlblob)
    return @metadata
  end
	
end
