ActionController::Routing::Routes.draw do |map|

  map.connect 'glycodbs', :controller => 'glycodbs', :action => 'index', :format => 'html'

  map.connect 'glycodbs/tags', :controller => 'glycodbs', :action => 'tags', :format => 'html'

  map.connect 'glycodbs/proteins', :controller => 'glycodbs', :action => 'proteins', :format => 'html'

  map.connect 'glycodbs/compare_tags/:tags1/:tags2', :controller => 'glycodbs', :action => 'compare_tag_summary'

  map.connect 'glycodbs/:id', :controller => 'glycodbs', :action => 'show', :format => 'html'
  
  map.connect 'glycodbs/tag/:id/:tag', :controller => 'glycodbs', :action => 'tag', :format => 'html'

  map.connect 'glycodbs.:format/tag/:id/:tag', :controller => 'glycodbs', :action => 'tag'

  map.connect 'glycodbs/untag/:id/:tag', :controller => 'glycodbs', :action => 'untag', :format => 'html'

  map.connect 'glycodbs.:format/untag/:id/:tag', :controller => 'glycodbs', :action => 'untag'

  map.resources :glycodbs

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
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect 'sugarviewer', :controller => 'sviewer', :action => 'show', :format => 'html'

  map.connect 'sugarlist', :controller => 'sviewer', :action => 'show_list', :format => 'html'

  map.connect 'sviewer.:format/:ns/:seq', :controller => 'sviewer', :action => 'index'
  
  map.connect 'sviewer.:format/:seq', :controller => 'sviewer', :action => 'index', :ns => 'dkfz'

  map.connect 'sviewer/:ns/:seq', :controller => 'sviewer', :action => 'index', :format => 'svg'

  map.connect 'sviewer/:seq', :controller => 'sviewer', :action => 'index', :ns => 'dkfz', :format => 'svg'

  map.connect 'tissue', :controller => 'enzymeinfos', :action => 'list_tissues'
  
  map.connect 'tissue/:mesh_tissue', :controller => 'enzymeinfos', :action => 'show_tissue'

  map.connect ':controller.:format/:action/:id/'

  map.connect ':controller/:action/', :format => 'html'

  #map.connect 'sviewer/:seq', :controller => 'sviewer', ':ns' => 'dkfz'

  map.connect ':controller/:action/:id', :format => 'html'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'



end
