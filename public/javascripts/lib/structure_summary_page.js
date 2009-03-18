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

function init_print_window() {
	a_window = window.open('','_blank');
	a_window.document.write('<xml version="1.0" standalone="no"?>\n');
	a_window.document.close();
	return a_window;	
}

function setup_print_document_style(target_document,title_element,width,height) {
	report_title = target_document.importNode(title_element,true);
	target_document.getElementsByTagName('body')[0].appendChild(report_title);
	target_document.getElementsByTagName('body')[0].style.position = 'relative';
	target_document.getElementsByTagName('body')[0].style.width = width+'cm';
	target_document.getElementsByTagName('body')[0].style.height = height+'cm';
	target_document.getElementsByTagName('body')[0].style.fontSize = '0.25cm';
	target_document.getElementsByTagName('body')[0].style.fontFamily = 'Helvetica,Arial,Sans-serif';
	target_document.print_width = width;
	target_document.print_height = height;
	
}

function append_print_document_key(target_document) {
	if ($('sugar_key') == null) {
		return;
	}
	doc_height = target_document.print_height;
	
	key_height = (1/6 * doc_height);
	
	copied_key = a_window.document.importNode($('sugar_key'),true);
	target_document.getElementsByTagName('body')[0].appendChild(copied_key);		
	copied_key.style.position = 'absolute';
	copied_key.style.top = ((2/3) * doc_height)+'cm';
	copied_key.style.width = '100%';
	copied_key.style.height = (key_height-0.5)+'cm';
}

function append_print_branch_graphs(target_document,graph_container) {

	doc_width = target_document.print_width;
	doc_height = target_document.print_height;
	
	copied_graph = target_document.importNode(graph_container,true);

	a_window.document.getElementsByTagName('body')[0].appendChild(copied_graph);
	
	top_height = (2/3 + 1/6)*doc_height;
	remaining_size = doc_height - top_height;

	copied_graph.style.position = 'absolute';
	copied_graph.style.top = (top_height - 1)+'cm';
	copied_graph.style.left = '0cm';
	copied_graph.style.width = doc_width+'cm';
	copied_graph.style.height = (remaining_size - 0.5)+'cm';

	
	each_graph = XHtmlDOM.getElementsByClassName('single_branch_graph',copied_graph);
	
	graph_width = doc_width / each_graph.length;
	
	for ( var i in each_graph ) {
		graph_svg = each_graph[i].getElementsByTagNameNS('http://www.w3.org/2000/svg','svg')[0];
		graph_svg.setAttribute('height',(remaining_size - 0.5)+'cm');
		each_graph[i].style.position = 'absolute';
		each_graph[i].style.left = ((graph_width*i) + 1)+'cm';
		each_graph[i].style.top = '0cm';
		each_graph[i].style.overflow = 'hidden';
		each_graph[i].style.width = (graph_width - 1)+'cm';
		each_graph[i].style.height = (remaining_size - 0.5)+'cm';
	}
}

function append_print_svgs(target_document,svgs) {
	width = target_document.print_width / svgs.length;
	height = (2 * target_document.print_height) / 3;

	for (i in svgs) {
		copied_svg = target_document.importNode(svgs[i],true);

		target_document.getElementsByTagName('body')[0].appendChild(copied_svg);
		setup_print_single_svg_style(copied_svg,width,height);

		copied_svg.style.left = i*width+'cm';
		
		groups = copied_svg.getElementsByTagNameNS('http://www.w3.org/2000/svg','g');
		
		for (var i = 0; i < groups.length; i++) {
			groups[i].removeAttribute('filter');
		}
	}
}

function setup_print_single_svg_style(new_svg,width,height) {
	new_svg.setAttribute('width',width+'cm');
	new_svg.setAttribute('height',height+'cm');	
	new_svg.style.position = 'absolute';
}

function do_printing(svg_element,result_structure_el) {
	a_window = init_print_window();
	
	setup_print_document_style(a_window.document,$('report_title'),20,29);
	
	append_print_svgs(a_window.document,[svg_element]);

	graph_container = XHtmlDOM.getElementsByClassName('branch_graphs',result_structure_el.parentNode)[0];

	append_print_branch_graphs(a_window.document,graph_container);

	append_print_document_key(a_window.document);
	
}

function do_summary_printing(sugar_result) {
	a_window = init_print_window();
	
	report_title = XHtmlDOM.getElementsByClassName('report_title',sugar_result)[0];

	setup_print_document_style(a_window.document,report_title,29,20);
	
	graph_container = $('summary_graphs');
	
	sugar_results = XHtmlDOM.getElementsByClassName('result_structure',sugar_result);
	
	all_svgs = [];
	
	for (i in sugar_results) {
		all_svgs.push(sugar_results[i].targetSVG);
	}

	append_print_svgs(a_window.document,all_svgs);


	append_print_branch_graphs(a_window.document,graph_container);
	
	append_print_document_key(a_window.document);	
}
