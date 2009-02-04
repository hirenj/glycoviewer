# Methods added to this helper will be available to all templates in the application.

require 'SugarHelper'

module ApplicationHelper
  def print_sugar(sugar_string,ns=:ecdb)
    SugarHelper.ConvertToIupac(sugar_string,ns=:ecdb)
  end  

  def write_sugar(sugar,options={})
    return SugarHelper.RenderSugar(sugar,:full,session[:sugarscheme],options)
  end

  def write_sugar_html(sugar)
    return SugarHelper.RenderSugarHtml(sugar)
  end

  def print_residue(res_string)
    SugarHelper.ConvertResidueName(:ecdb,res_string,:ic)
  end

end
