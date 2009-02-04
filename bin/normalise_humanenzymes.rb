#!/usr/bin/env ruby

# This script imports structures from the original CSV file used for
# collecting the enzyme information

require File.dirname(__FILE__) + '/script_common'

require 'rubygems'
gem 'builder', '~> 2.0'
gem 'xml-mapping'

require "rexml/document"
include REXML

require 'app/models/enzyme_reaction.rb'
require 'app/models/reaction.rb'
require 'app/models/enzymeinfo.rb'
require 'app/models/geneinfo.rb'

require "csv"

class Converter
	include DebugLog

	private

	def build_db_connection
		# Read database config via YAML
		@dbs = YAML::load(ERB.new(IO.read("config/database.yml")).result)
		# connect to old db.
		curr_db = @dbs[ENV['RAILS_ENV']]
		
		ActiveRecord::Base.establish_connection(:adapter => curr_db["adapter"],
		:database => curr_db["database"],
		:host => curr_db["host"],
		:username => curr_db["username"],
		:password => curr_db["password"])
	end
	
	def close_db_connection
		ActiveRecord::Base.remove_connection
	end

	public
	
	def read_db_from_csv(filename,test=false)

		#build_db_connection
		row_id = 0
		added_rows = 0

		CSV::Reader.parse(File.open(filename, 'rb')) do |row|
			begin
				reaction = Reaction.new()
				
				raise ConverterException.new("Incomplete data, missing donor")	unless
					row[0]
					
				raise ConverterException.new("Incomplete data, missing substrate")	unless					
					row[4]
					
				raise ConverterException.new("Incomplete data, missing end structure")	unless										
					row[5]

				raise ConverterException.new("Incomplete data, missing Gene name")	unless															
					row[6]

#				raise ConverterException.new("Incomplete data, missing Cazy family")	unless															
#					row[7]
				
				sugar = SugarHelper.CreateSugar(row[0].data.strip,:ic)
				reaction.residuedelta = sugar.sequence
        sugar.finish

				sugar = SugarHelper.CreateSugar(row[4].data.strip,:ic)
				reaction.substrate = sugar.sequence				
				sugar.finish

				sugar = SugarHelper.CreateSugar(row[5].data.strip,:ic)
				reaction.endstructure = sugar.sequence				
				sugar.finish

				enzinfo = Enzymeinfo.new()
				geneinfo = Geneinfo.new()
				
				geneinfo.genename = row[6].data.strip

				enzinfo.geneinfo = geneinfo
				enzinfo.cazyid = row[7] ? row[7].data.strip : ''

				enzreac = EnzymeReaction.new()
				enzreac.enzymeinfo = enzinfo
				enzreac.reaction = reaction

        if (! test)
				  enzreac.save!
        end
        added_rows = added_rows + 1
			rescue SugarException => exception
				error "Error in sequence on row #{row_id} " + exception.message
				info row.join(",\t")
			rescue ConverterException => exception
				error "Skipping row #{row_id} " + exception.message
				info row.join(",\t")
			rescue ActiveRecord::RecordInvalid => exception
				error "Skipping row #{row_id} " + exception.message
				info row.join(",\t")
			rescue ActiveRecord::RecordNotSaved => exception
				error "Row #{row_id} not saved... " + exception.message
				info row.join(",\t")			  
			rescue Exception => exception
				error "Row #{row_id} not saved... " + exception.message
				info row.join(",\t")			  
			end
			row_id = row_id + 1
		end
    info "Inserted #{added_rows} rows"
		
		close_db_connection
		
	end
end

class ConverterException < Exception
end


require 'optparse'

opts = {
	:verbose => 4,
	:test => false
}
verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby normalise_humanenzymes.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.on("-I", "--infile FILE", String, "Import data into database") { |opts[:infile]| }
  opt.on("-t", "--test", TrueClass, "Test only (don't do anything)") { |opts[:test]| }

  opt.parse!

}

#ActiveRecord::Base.logger = Logger.new(STDERR)
DebugLog.log_level(opts[:verbose])

Converter.new.read_db_from_csv(opts[:infile], opts[:test])
