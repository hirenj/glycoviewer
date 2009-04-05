require 'importer'

namespace :enzymedb do
  desc "Export basic data from the database"
  task :dumpdb, :outfile, :needs => :environment do |t,args|
    Importer.new.write_db_to_file(args.outfile)
  end
  task :
end

namesapce :enzymedb do
  desc "Import basic data into the database"
  task :loaddb, :infile, :needs => :environment do |t,args|
    Importer.new.read_db_from_file(args.infile)
  end
end

namesapce :enzymedb do
  desc "Wipe basic data from the database"
  task :cleandb, :needs => :environment do |t,args|
    Importer.new.empty_database
  end
end