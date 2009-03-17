function connect_buttons(sugar_canvas) {
	target_svg = sugar_canvas.targetSVG;

	gene_toggle = XHtmlDOM.getElementsByClassName('gene_toggle',sugar_canvas)[0];
	hits_toggle = XHtmlDOM.getElementsByClassName('hits_toggle',sugar_canvas)[0];

	a_printer = XHtmlDOM.getElementsByClassName('print_button',sugar_canvas)[0];

	gene_layer = XHtmlDOM.getElementsByClassName('gene_overlay',target_svg)[0];

	hits_layer = XHtmlDOM.getElementsByClassName('hits_overlay',target_svg)[0];
	
	connect(gene_toggle,'onclick',partial(togglelayer,gene_layer));
	connect(hits_toggle,'onclick',partial(togglelayer,hits_layer));

	connect(a_printer,'onclick',partial(do_printing,target_svg,sugar_canvas));
	
	togglelayer(gene_layer);		
}

function connect_slider(sugar_canvas) {
	original_width = sugar_canvas.targetSVG.getAttribute('width');
	original_height = sugar_canvas.targetSVG.getAttribute('height');

	slider = new SugarBuilder.Slider();
	slider.canvas().style.zIndex = 2;
	appendChildNodes(sugar_canvas,slider.canvas());
	connect(slider,'onchange',partial(changescale,sugar_canvas.targetSVG,original_width,original_height));
}
	
function togglelayer(svg_group) {
	if (svg_group.getAttribute('display')) {
		svg_group.removeAttribute('display');
	} else {
		svg_group.setAttribute('display','none');
	}
}

function changescale(svg,original_width,original_height,e) {
	scale = e.target().value;
	svg.setAttribute('width', original_width*scale);
	svg.setAttribute('height', original_height*scale);
}

function build_tabs() {
	var myTabs = new YAHOO.widget.TabView("coverage_tabs");
}

function do_printing(svg_element,result_structure_el) {
	a_window = window.open('','_blank');
	a_window.document.write('<xml version="1.0" standalone="no"?>\n');
	a_window.document.close();
	
	report_title = a_window.document.importNode($('report_title'),true);

	a_window.document.getElementsByTagName('body')[0].appendChild(report_title);

	copied_svg = a_window.document.importNode(svg_element,true);
	
	a_window.document.getElementsByTagName('body')[0].appendChild(copied_svg);
	
	copied_svg.setAttribute('width','80cm');
	copied_svg.setAttribute('height','80cm');
	
	groups = copied_svg.getElementsByTagNameNS('http://www.w3.org/2000/svg','g');
	for (var i = 0; i < groups.length; i++) {
		groups[i].removeAttribute('filter');
	}

	graph_container = XHtmlDOM.getElementsByClassName('branch_graphs',result_structure_el.parentNode)[0];
	
	copied_graph = a_window.document.importNode(graph_container,true);

	a_window.document.getElementsByTagName('body')[0].appendChild(copied_graph);
	
	copied_graph.style.position = 'absolute';
	copied_graph.style.bottom = '-15cm';
	copied_graph.style.right = '0px';
	copied_graph.style.width = '100%';
	copied_graph.style.height = '20cm';

	
	a_window.document.getElementsByTagName('body')[0].style.position = 'relative';
	a_window.document.getElementsByTagName('body')[0].style.width = '80cm';
	a_window.document.getElementsByTagName('body')[0].style.height = '120cm';
	a_window.document.getElementsByTagName('body')[0].style.fontSize = '1.5cm';
	a_window.document.getElementsByTagName('body')[0].style.fontFamily = 'Helvetica,Arial,Sans-serif';
			

	each_graph = XHtmlDOM.getElementsByClassName('single_branch_graph',copied_graph);
	
	for ( var i in each_graph ) {
		each_graph[i].style.float = 'left';
		each_graph[i].style.width = '12cm';
		each_graph[i].style.height = '16cm';
		each_graph[i].style.padding = '0.5cm';
	}
	
	copied_key = a_window.document.importNode($('sugar_key'),true);
	a_window.document.getElementsByTagName('body')[0].appendChild(copied_key);		
	copied_key.style.position = 'absolute';
	copied_key.style.bottom = '15cm';
	copied_key.style.width = '100%';
	copied_key.style.height = '20cm';
}
