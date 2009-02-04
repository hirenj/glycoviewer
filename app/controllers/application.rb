# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  before_filter :set_db_schema

  #This really should not be harcoded in here...
  @@valid_tissues = ['ovary']
  
  def set_db_schema
    tax_id = params[:taxonomy_id] || session[:taxonomy_id] || ''
    tissue = params[:tissue] || session[:tissue] || ''
    schema_name = tax_id.is_numeric? ? "tax#{tax_id}" : 'public'
    if @@valid_tissues.include?( tissue )
      schema_name += "tissue#{tissue}"
    end
    if ActiveRecord::Base::connection.respond_to?(:schema_search_path)
      ActiveRecord::Base::connection.schema_search_path = schema_name
      logger.info "Setting schema to #{ActiveRecord::Base::connection.schema_search_path} for searches. If queries are failing, make sure that the schema exists, and that permissions are given for the current database user."
    end
  end
end