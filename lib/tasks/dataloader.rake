namespace :enzymedb do
  desc "Import and export basic data from the database"
  task :dumpdb, :outfile, :needs => :environment do |t,args|
    Importer.new.write_db_to_file(args.outfile)
  end
end