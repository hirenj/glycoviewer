ActionController::Routing::Routes.draw do |map|

  if ENV['RAILS_ENV'] == 'development'
    map.connect 'glycodbs', :controller => 'glycodbs', :action => 'index', :format => 'html'

    map.connect 'glycodbs/tags', :controller => 'glycodbs', :action => 'tags', :format => 'html'

    map.connect 'glycodbs/proteins', :controller => 'glycodbs', :action => 'proteins', :format => 'html'

  end

  map.connect 'structures', :controller => 'glycodbs', :action => 'tags', :format => 'html'

  map.connect 'structures/coverage_for_tag/:id', :controller => 'glycodbs', :action => 'coverage_for_tag'

  map.connect 'structures/compare_tags/:tags1/:tags2', :controller => 'glycodbs', :action => 'compare_tag_summary'

  if ENV['RAILS_ENV'] == 'development'
    
    map.connect 'glycodbs/:id', :controller => 'glycodbs', :action => 'show', :format => 'html'

    map.connect 'glycodbs/tag/:id/:tag', :controller => 'glycodbs', :action => 'tag', :format => 'html'

    map.connect 'glycodbs/untag/:id/:tag', :controller => 'glycodbs', :action => 'untag', :format => 'html'

    map.connect 'glycodbs/ws-tag', :controller => 'glycodbs', :action => 'tag', :format => 'txt'

    map.connect 'glycodbs/ws-untag', :controller => 'glycodbs', :action => 'untag', :format => 'txt'

    map.connect 'glycodbs/ws-tag/:id/:tag', :controller => 'glycodbs', :action => 'tag', :format => 'txt'

    map.connect 'glycodbs/ws-untag/:id/:tag', :controller => 'glycodbs', :action => 'untag', :format => 'txt'

    map.resources :glycodbs

  end



  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  if ENV['RAILS_ENV'] == 'development'  

    map.connect ':controller/service.wsdl', :action => 'wsdl'

    map.connect 'sugarlist', :controller => 'sviewer', :action => 'show_list', :format => 'html'

  end

  map.connect 'help', :controller => 'glycodbs', :action => 'help', :format => 'html'
  map.connect 'help_output', :controller => 'glycodbs', :action => 'help_output', :format => 'html'
  map.connect 'help_contact', :controller => 'glycodbs', :action => 'help_contact', :format => 'html'

  map.connect 'sugarviewer', :controller => 'sviewer', :action => 'show', :format => 'html'

  map.connect 'sviewer_thumbs/:width/:height/:schema/:ns/:seq.png', :format => 'png', :controller => 'sviewer', :action => 'index'

  map.connect 'sviewer.:format', :controller => 'sviewer'

  map.connect 'sviewer/:ns', :controller => 'sviewer', :action => 'index', :format => 'png'

  map.connect 'sviewer/:schema/:ns/:seq.:format', :controller => 'sviewer', :action => 'index'

  map.connect 'sviewer/:schema/:ns/:seq', :controller => 'sviewer', :action => 'index', :format => 'png'

  map.connect 'sviewer/:ns/:seq.:format', :controller => 'sviewer', :action => 'index'
  
  map.connect 'sviewer/:seq.:format', :controller => 'sviewer', :action => 'index', :ns => 'dkfz'

  map.connect 'sviewer/:ns/:seq', :controller => 'sviewer', :action => 'index', :format => 'svg'

  map.connect 'sviewer/:seq', :controller => 'sviewer', :action => 'index', :ns => 'dkfz', :format => 'svg'



  if ENV['RAILS_ENV'] == 'development'
    map.connect 'tissue', :controller => 'enzymeinfos', :action => 'list_tissues'
  
    map.connect 'tissue/:mesh_tissue', :controller => 'enzymeinfos', :action => 'show_tissue'
  end
  
  if ENV['RAILS_ENV'] == 'development'
    map.connect ':controller/:action/:id.:format'

    map.connect ':controller/:action.:format'

    map.connect ':controller/:action/', :format => 'xhtml'

    #map.connect 'sviewer/:seq', :controller => 'sviewer', ':ns' => 'dkfz'

    map.connect ':controller/:action/:id', :format => 'html'

  else


    ['config','sugarbuilder','sequence_sets'].each { |action|

      map.connect "#{action}/:action.:format", :controller => action
    
      map.connect "#{action}/:action", :controller => action

      map.connect "#{action}", :controller => action
    }
    
    map.connect ':controller/:action/:id.:format', :disabled_action => true

    map.connect ':controller/:action.:format', :disabled_action => true

    map.connect ':controller/:action/', :format => 'xhtml', :disabled_action => true

    map.connect ':controller/:action/:id', :format => 'html', :disabled_action => true

  end

  map.connect '/', :controller => 'glycodbs', :action => 'home', :format => 'html'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'


end
