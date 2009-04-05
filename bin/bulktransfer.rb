#!/usr/bin/env ruby

$:.push('SugarCoreRuby/lib')

#RAILS_ENV = 'development'
RAILS_ROOT = File.dirname(__FILE__) + '/..'
require File.dirname(__FILE__) + '/../config/environment'

require 'rubygems'
require "logger"

gem 'builder', '~> 2.0'
gem 'xml-mapping'

require "rexml/document"
include REXML


require 'app/models/enzyme_reaction.rb'
require 'app/models/reaction.rb'
require 'app/models/enzymeinfo.rb'
require 'app/models/geneinfo.rb'
require 'app/models/disaccharide.rb'

require 'SugarHelper'

@logger = Logger.new(STDERR)
ActiveRecord::Base.logger = @logger

module ActiveRecord
	class Base
    # XML Deserializer for ActiveRecord
    # by Wayne Robinson and Dominic Orchard
    def self.from_xml(xml)
      if xml.class == String
          # If passed a string, convert to XML object, and set root
          xml = REXML::Document.new(xml) 
          root = xml.elements[1]
      else
          # If already passed an XML object, then set root to XML object
          root = xml
      end
      
      if  ((root.name.underscore != self.class_name.underscore) and 
             (root.name.underscore != self.class_name.pluralize.underscore))
              # Check the top level is actual refering to the class
              # e.g. , for class Customer
             return nil
      end
      
      # Deal with XML data containing many record instances
      if (root.name.underscore == self.class_name.pluralize.underscore and self.class_name.pluralize.underscore!=self.class_name.underscore) or root.name==root.elements[1].name
            root.elements.inject(nil,[]) do |instances, element|
                instances.push(self.from_xml(element))
            end

        else
            # Try to retrieve from ID in
            # XML data and update this record or start a new record
            # Find an id element in the elements
            id_element = root.elements.inject(nil) do |found, element|
                  if element.name=="id"
                        element
                  else
                        found
                  end
            end
            # if we haven't found the ID element
            if id_element.nil?
                  new_record = self.new
            else
                  # Retrieve from XML
                  begin            
                      new_record = self.find(id_element.text.to_i)
                  rescue
                      # If that record in fact didn't exist... start a new one
                      new_record = self.new
                  end
            end
            
            # Iterate through elements
            root.elements.each do | element |
                sym = element.name.underscore.to_sym
      
                # An association
              if element.has_elements?
  
                setter = (sym.to_s+"=")
                # Check the setter is an instance method
                if self.instance_methods.member?(setter)
                      klass = self.reflect_on_association(sym).klass
                      new_record.__send__(setter.to_sym, klass.from_xml(element))
                end
    
              # An attribute
              else
                  # Check that the attribute is actual part of the record
                  if new_record.attributes.member?(sym.to_s) || sym==:id
                      if element.text.nil?              
                            col = new_record.column_for_attribute(sym)
                            # Handle an empty element with a not null column
                            if !col.null
                                # Use default value 
                                new_record[sym] = col.default
                            end
                      else
                            new_record[sym] = element.text
                      end
                  end
             end
          end
  
          new_record
        end
     end
	end
end

class Importer

attr_accessor :test

def build_db_connection
	# Read database config via YAML
	@dbs = YAML::load(ERB.new(IO.read("config/database.yml")).result)
	# connect to old db.
	curr_db = @dbs[RAILS_ENV]
	
	ActiveRecord::Base.establish_connection(:adapter => curr_db["adapter"],
	:database => curr_db["database"],
	:host => curr_db["host"],
	:username => curr_db["username"],
	:password => curr_db["password"])
end

def empty_database
  EnzymeReaction.find(:all).each { |er| er.destroy }
  Disaccharide.find(:all).each { |d| d.destroy }
  Geneinfo.find(:all).each { |g| g.destroy }
  Enzymeinfo.find(:all).each { |e| e.destroy }
  Reaction.find(:all).each { |r| r.destroy }
end

def close_db_connection
	ActiveRecord::Base.remove_connection
end

def write_db_to_export_file(filename=nil) 
	build_db_connection()
	doc = Document.new
	doc.add_element(Element.new("reactions"))
	
	@reactions = Reaction.find(:all)
	@reactions.each { |react|
		react.substrate = SugarHelper.ConvertToIupac(react.substrate)
		react.endstructure = SugarHelper.ConvertToIupac(react.endstructure)
		react.residuedelta = SugarHelper.ConvertToIupac(react.residuedelta)

		reactxml = Document.new(react.to_xml(:skip_instruct => true))
		enzymes = reactxml.root.add_element(Element.new("enzymes"))
		react.enzyme_reactions.each { |enzreact| 
		  enzymes.add_element( Document.new(enzreact.enzymeinfo.to_xml(:skip_instruct => true)).root ).add_element( Document.new(enzreact.enzymeinfo.geneinfo.to_xml(:skip_instruct => true)).root )
	  }
		doc.root.add_element(reactxml.root)
	}
	close_db_connection()

	if filename
		doc.write(open(filename,"w"))
	else
		doc.write
	end
	
end

def write_db_to_file(filename=nil) 
	build_db_connection()
	doc = Document.new
	doc.add_element(Element.new("reactions"))
	
	@reactions = EnzymeReaction.find(:all)
	seen_genes = []

	counter = 1
	@reactions.each { |enz_react|

		reactxml = Document.new(enz_react.to_xml(:skip_instruct => true)).root
		reactxml.add_element( Document.new(enz_react.enzymeinfo.to_xml(:skip_instruct => true)).root ).
		         add_element( Document.new(enz_react.enzymeinfo.geneinfo.to_xml(:skip_instruct => true)).root )
		seen_genes << enz_react.enzymeinfo.geneinfo
		reactxml.add_element( Document.new(enz_react.reaction.to_xml(:skip_instruct => true)).root )
		reactxml.add_element( Document.new(enz_react.refs.to_xml(:skip_instruct => true)).root )
		doc.root.add_element(reactxml)
	  ActiveRecord::Base.logger.info("\e[1F\e[KWriting #{counter}/#{@reactions.size} step 1/5")
	  counter += 1
	}

	counter = 1
	free_reactions = doc.root.add_element(Element.new("free-reactions"))
	free_reacs = Reaction.find(:all).delete_if { |r| r.has_enzyme? }
	free_reacs.each { |reac|
	  free_reactions.add_element( Document.new(reac.to_xml(:skip_instruct => true)).root )
	  ActiveRecord::Base.logger.info("\e[1F\e[KWriting #{counter}/#{free_reacs.size} step 2/5")
	  counter += 1
	}
	
	counter = 1
	free_genes = doc.root.add_element(Element.new("free-genes"))	
	free_geneinfos = (Geneinfo.find(:all) - seen_genes)
	free_geneinfos.each { |g|
	  free_genes.add_element( Document.new(g.to_xml(:skip_instruct => true)).root )
	  ActiveRecord::Base.logger.info("\e[1F\e[KWriting #{counter}/#{free_geneinfos.size} step 3/5")
	  counter += 1
	}

	counter = 1
	free_enzymes = doc.root.add_element(Element.new("free-enzymes"))
	free_enzymeinfos = Enzymeinfo.find(:all).delete_if { |e| e.has_reaction? }
	free_enzymeinfos.each { |enzyme|
	  free_enzymes.add_element( Document.new(enzyme.to_xml(:skip_instruct => true)).root )	  
	  ActiveRecord::Base.logger.info("\e[1F\e[KWriting #{counter}/#{free_enzymeinfos.size} step 4/5")
	  counter += 1
  }
	
	@disacs = Disaccharide.find(:all)
  disac_doc = Document.new
	disac_el = disac_doc.add_element(Element.new("disaccharides"))
  counter = 1
	@disacs.each { |disac|
    disac_xml = Document.new(disac.to_xml(:skip_instruct => true)).root
    disac_el.root.add_element(disac_xml)
	  ActiveRecord::Base.logger.info("\e[1F\e[KWriting #{counter}/#{@disacs.size} step 5/5")    
	  counter += 1
	}
	
	
	close_db_connection()

  return if test

	if filename
		doc.write(open(filename,"w"))
	else
		doc.write
	end

	if filename
		disac_doc.write(open("disaccharides-#{filename}","w"))
	else
		disac_doc.write
	end
	
end


def read_db_from_file(filename)
	build_db_connection()
  doc = Document.new(File.new(filename))

  doc.elements.each('//enzyme-reaction') { |child|

    reac = EnzymeReaction.from_xml(child)
    next if test

    if reac.save()
      @logger.debug("Stored EnzymeReaction #{reac.id}")
    else
      @logger.debug("Error storing EnzymeReaction")
      reac.errors.each_full { |message| 
        @logger.debug("With message: #{message}")
      }
    end
  }
  doc.elements.each('//free-reactions/reaction') { |child|
    reac = Reaction.from_xml(child)

    next if test

    if reac.save()
      @logger.debug("Stored Reaction #{reac.id}")
    else
      @logger.debug("Error storing Reaction")
      reac.errors.each_full { |message| 
        @logger.debug("With message: #{message}")
      }
    end    
  }
  doc.elements.each('//free-genes/geneinfo') { |child|
    gene = Geneinfo.from_xml(child)
    
    next if test
    
    if gene.save()
      @logger.debug("Stored Geneinfo #{gene.id}")
    else
      @logger.debug("Error storing Geneinfo")
      gene.errors.each_full { |message| 
        @logger.debug("With message: #{message}")
      }
    end    
  }

  doc.elements.each('//free-enzymes/enzymeinfo') { |child|
    enzyme = Enzymeinfo.from_xml(child)
    
    next if test
    
    if enzyme.save()
      @logger.debug("Stored Enzymeinfo #{enzyme.id}")
    else
      @logger.debug("Error storing Enzymeinfo")
      enzyme.errors.each_full { |message| 
        @logger.debug("With message: #{message}")
      }
    end    
  }

  doc = Document.new(File.new("disaccharides-#{filename}"))

  doc.elements.each('//disaccharide') { |child|

    disac = Disaccharide.from_xml(child)
    next if test

    if disac.save()
      @logger.debug("Stored Disaccharide #{disac.id}")
    else
      @logger.debug("Error storing Disaccharide")
      reac.errors.each_full { |message| 
        @logger.debug("With message: #{message}")
      }
    end
  }

	close_db_connection()
end


end

require 'optparse'

opts = {
	:verbose => 5,
	:test => false
}
verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby bulktransfer.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.on("-O", "--outfile FILE", String, "Write output to this file") { |opts[:outfile]| }
  opt.on("-I", "--infile FILE", String, "Import data into database") { |opts[:infile]| }
  opt.on("-c", "--clean-db",String, "Clean out the database / remove all entries") { opts[:action] = "resetdb" }
  opt.on("-d", "--dump-db", String, "Perform a dump of the database") { opts[:action] = "dumpdb" }
  opt.on("-i", "--import-db", String, "Import data into database") { opts[:action] = "importdb" }
  opt.on("-t", "--test",String, "Test only") { opts[:test] = true }
  opt.on("-s", "--disaccharides", String, "Filename to read or write disaccharides to/from") { opts[:disaccharide_data] = "disaccharides.xml"}
  #opt.on("-d", "--dump-geneinfo", String, "Dump the gene info") { |outfile| Importer.new.write_db_to_file(opts[:outfile]); exit 0 }
  #opt.on("-i", "--import-geneinfo", String, "Import set of gene info data") { |infile| Importer.new.read_db_from_file(opts[:infile]); exit 0 }

  opt.parse!

}

@logger.level = opts[:verbose]

importer = Importer.new

importer.test = opts[:test]

case opts[:action]
  when "resetdb" then
    Importer.new.empty_database
	when "dumpdb" then
		Importer.new.write_db_to_file(opts[:outfile])
		exit 0
	when "importdb" then
		Importer.new.read_db_from_file(opts[:infile])
		exit 0
end
