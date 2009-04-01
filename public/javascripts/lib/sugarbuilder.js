if ( typeof(SugarBuilder) == undefined ) {
	SugarBuilder = {};
}

SugarBuilder = function(builderURL,sequence,opts) {
	this.builderURL = builderURL;
	this._state['sequence'] = sequence;
	this._setupBuilder();
	if (opts != null) {
		this.opts = merge(this.opts,opts);
	}
};

SugarBuilder.prototype = {
	__class__: SugarBuilder,
	targetElement: null,
	_state: { 			'current_target'	: null,
						'in_drag' 				: false,
						'last_draggable'	: null,
						'sequence'				: '',
						'scale'						: 1,
						'anomer'					: null,
						'firstposition'		: 0,
						'secondposition'	: 0,
						'mode'				: 'build'
					},
	opts: {	'drop_target_class': 'drop_target',
					'pallette_element_class': 'pallette_element'
				},
	build_elements: { 'svg_canvas'		: 'svg_box',
										'params_overlay': 'parameters',
										'build_button'  : 'buildstruct'
				}
};

SugarBuilder.prototype._getValue = function(el) {
	return el.value;
}

SugarBuilder.prototype._signalMouseStopped = function(delay,e) {
	state = this._state;
	if (state['mouseStopped']) {
		state['mouseStopped'].cancel();
		state['mouseStopped'] = null;
	}
	state['mouseStopped'] = callLater(delay,bind(this._fireMouseStopped,this),e);
};

SugarBuilder.prototype._fireMouseStopped = function(e) {
	state = this._state;
	state['mouseStopped'] = null;
	signal(e.target(),'onmousestop');
};


SugarBuilder.prototype._setupAnomerOverlay = function() {
	anomer_names = { 'a': 'α','u':'?','b':'β'};
	anomers = DIV({'class':'sugarbuilder_anomers'});
	total_size = 0;
	for (var i in anomer_names) {
		total_size = total_size + 1;
	}
	last_x = 50;
	last_y = 0;
	last_x2 = 50;
	last_y2 = 40;
	counter = 0;
	anomer_svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
	anomer_svg.setAttribute('width','100');
	anomer_svg.setAttribute('height','100');
	anomer_labels = document.createElementNS('http://www.w3.org/2000/svg','g');
	anomer_backs = document.createElementNS('http://www.w3.org/2000/svg','g');

	appendChildNodes(anomer_svg,anomer_backs);
	appendChildNodes(anomer_svg,anomer_labels);

	for (var i in anomer_names) {
		counter = counter + 1;
		xpos = 50 + 50 * Math.cos(Math.PI*(2*counter / total_size + 0.5));
		ypos = 50 - 50 * Math.sin(Math.PI*(2*counter / total_size + 0.5));
		xpos2 = 50 + 10 * Math.cos(Math.PI*(2*counter / total_size + 0.5));
		ypos2 = 50 - 10 * Math.sin(Math.PI*(2*counter / total_size + 0.5));

		arc_string = "M"+last_x+","+last_y+" A50,50 0 0,0 "+xpos+","+ypos+" L"+xpos2+","+ypos2+" A10,10 0 0,1 "+last_x2+","+last_y2+" Z"

		arc = document.createElementNS('http://www.w3.org/2000/svg','path');
		arc.setAttribute('d',arc_string);
		arc.setAttribute('style','opacity: 0.1; fill: #ffffff; stroke: none; stroke-width: 0;');
		
		arc_back = document.createElementNS('http://www.w3.org/2000/svg','path');
		arc_back.setAttribute('d',arc_string);
		arc_back.setAttribute('class', 'anomer_pie_slice pie_slice')
		arc_back.setAttribute('style','opacity: 1; fill: #dddddd; stroke: black; stroke-width: 1;');
		
		
		connect(arc,'onmousestop',this,partial(this._acceptAnomer,i));
		connect(arc,'onmousemove',this,partial(this._signalMouseStopped,0.4));
		arc_label = document.createElementNS('http://www.w3.org/2000/svg','text');
		label_xpos = 50 + 30 * Math.cos(Math.PI * ( 0.5 + (2*counter - 1) / total_size ));
		label_ypos = 50 - 30 * Math.sin(Math.PI * ( 0.5 + (2*counter - 1) / total_size ));
		
		arc_label.setAttribute('x',label_xpos);
		arc_label.setAttribute('y',label_ypos+10);
		appendChildNodes(arc_label,document.createTextNode(anomer_names[i]));
		arc_label.setAttribute('font-family', 'Helvetica');
		arc_label.setAttribute('text-anchor','middle');
		arc_label.setAttribute('font-size','25');
		arc_label.setAttribute('fill','#000000');

		appendChildNodes(anomer_svg,arc);
		appendChildNodes(anomer_labels,arc_label);
		appendChildNodes(anomer_backs,arc_back);

		last_x = xpos;
		last_y = ypos;
		last_x2 = xpos2;
		last_y2 = ypos2;
	}

	appendChildNodes(anomers,anomer_svg);

	anomer_overlay = new YAHOO.widget.Overlay(anomers);
	anomer_overlay.cfg.setProperty("visible",false);
	anomer_overlay.cfg.setProperty("width", '100px');
	anomer_overlay.cfg.setProperty("height",'100px');
	anomer_overlay.cfg.setProperty('zindex', '2');
	this.build_elements['anomer_overlay'] = anomer_overlay;
	
	connect(anomers,'onmouseout',this,
		function(e) {
			anomer_els = e.target().getElementsByTagName('div');
			for (var i = 0 ; i < anomer_els.length; i++) {
				if (e.relatedTarget() == anomer_els[i]) {
					return;
				}
				this._restartParameterSetting("anomer");
			}
		});
		
	appendChildNodes(document.getElementsByTagName('body')[0],anomers);	
};

SugarBuilder.prototype._setupLinkageOverlay = function() {
	link_names = [2,3,4,5,6,'?'];
	links = DIV({'class':'sugarbuilder_linkages'});

	total_size = 0;
	for (var i in link_names) {
		total_size = total_size + 1;
	}
	last_x = 50;
	last_y = 0;
	last_x2 = 50;
	last_y2 = 49;
	counter = 0;

	link_svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
	link_svg.setAttribute('width','100');
	link_svg.setAttribute('height','100');
	link_labels = document.createElementNS('http://www.w3.org/2000/svg','g');
	link_backs = document.createElementNS('http://www.w3.org/2000/svg','g');
	appendChildNodes(link_svg,link_backs);
	appendChildNodes(link_svg,link_labels);
	
	for (var i in link_names) {
		counter = counter + 1;
		xpos = 50 + 50 * Math.cos(Math.PI*(2*counter / total_size + 0.5));
		ypos = 50 - 50 * Math.sin(Math.PI*(2*counter / total_size + 0.5));
		xpos2 = 50 + 1 * Math.cos(Math.PI*(2*counter / total_size + 0.5));
		ypos2 = 50 - 1 * Math.sin(Math.PI*(2*counter / total_size + 0.5));

		arc_string = "M"+last_x+","+last_y+" A50,50 0 0,0 "+xpos+","+ypos+" L"+xpos2+","+ypos2+" A1,1 0 0,1 "+last_x2+","+last_y2+" Z"

		arc_back = document.createElementNS('http://www.w3.org/2000/svg','path');
		arc_back.setAttribute('d',arc_string);
		arc_back.setAttribute('style','fill: #dddddd; stroke: black; stroke-width: 1;');
		arc_back.setAttribute('class','link_pie_slice pie_slice sugarbuilder_link sugarbuilder_link_'+link_names[i]);
		arc_back.setAttribute('id','sugarbuilder_link_'+link_names[i]);


		arc = document.createElementNS('http://www.w3.org/2000/svg','path');
		arc.setAttribute('d',arc_string);
		arc.setAttribute('style','opacity: 0.1; fill: #ffffff;');


		connect(arc,'onmousestop',this,partial(this._acceptLinkage,link_names[i]));
		connect(arc,'onmousemove',this,partial(this._signalMouseStopped,0));

		arc_label = document.createElementNS('http://www.w3.org/2000/svg','text');
		label_xpos = 50 + 30 * Math.cos(Math.PI * ( 0.5 + (2*counter - 1) / total_size ));
		label_ypos = 50 - 30 * Math.sin(Math.PI * ( 0.5 + (2*counter - 1) / total_size ));
		
		arc_label.setAttribute('x',label_xpos);
		arc_label.setAttribute('y',label_ypos+10);
		appendChildNodes(arc_label,document.createTextNode(link_names[i]));
		arc_label.setAttribute('font-family', 'Helvetica');
		arc_label.setAttribute('text-anchor','middle');
		arc_label.setAttribute('font-size','25');
		arc_label.setAttribute('fill','#000000');

		appendChildNodes(link_svg,arc);
		appendChildNodes(link_labels,arc_label);
		appendChildNodes(link_backs,arc_back);

		last_x = xpos;
		last_y = ypos;
		last_x2 = xpos2;
		last_y2 = ypos2;
	}

	appendChildNodes(links,link_svg);

	connect(anomers,'onmouseout',this,
		function(e) {
			link_els = e.target().getElementsByTagName('div');
			for (var i = 0 ; i < link_els.length; i++) {
				if (e.relatedTarget() == link_els[i]) {					
					return;
				}
				this._restartParameterSetting("link");
			}
		});

	link_overlay = new YAHOO.widget.Overlay(links);
	link_overlay.cfg.setProperty("visible",false);
	link_overlay.cfg.setProperty("width", '50px');
	link_overlay.cfg.setProperty("height",'50px');
	link_overlay.cfg.setProperty('zindex', '2');

	this.build_elements['linkage_overlay'] = link_overlay;
	appendChildNodes(document.getElementsByTagName('body')[0],links);
};

SugarBuilder.prototype._setupSvgCanvas = function() {
	this.build_elements['svg_canvas'] = XHtmlDOM.makeElement('div');
	updateNodeAttributes(this.build_elements['svg_canvas'],
		{ 'style' : 'z-index: 1; position: relative; overflow: auto;',
		  'class' : 'sugarbuilder_canvas'
	  });
};

SugarBuilder.prototype.set_anomer = function(anomer) {
	this._state['anomer'] = anomer;
}

SugarBuilder.prototype.set_first_position = function(pos) {
	this._state['firstposition'] = pos;
}

SugarBuilder.prototype.set_second_position = function(pos) {
	this._state['secondposition'] = pos;
}

SugarBuilder.prototype.set_sequence = function(sequence) {
	this._state['sequence'] = sequence;
	signal(this,'sequencechange');
}

SugarBuilder.prototype.get_sequence = function() {
	return this._state['sequence']
}

SugarBuilder.prototype.get_ic_sequence = function() {
	return this._state['ic_sequence']
}

SugarBuilder.prototype.set_scale = function(scalefactor) {
	this._state['scale'] = scalefactor;
	signal(this,'scalechange');
	this.refresh_structure('null');
}

SugarBuilder.prototype.get_scale = function() {
	return this._state['scale'];
}

SugarBuilder.prototype.canvas = function() {
	return this.build_elements['svg_canvas'];
}

SugarBuilder.prototype.set_prune_mode = function(prunemode) {
	this._state['mode'] = prunemode ? 'prune' : 'build';
}

SugarBuilder.prototype.build_structure = function(linkagepath) {
	state = this._state;
	if (linkagepath == null) {
		return;
	}
	if (state['newres'].match(/neu/)) {
		this.set_second_position(2);
	}
	
	this.refresh_structure(linkagepath);
};

SugarBuilder.prototype.refresh_structure = function(linkagepath) {
	state = this._state;
	querystring = queryString(
		["identifier","seq",
		"newresidue","anomer","firstposn",
		"secondposn","scale"],
		
		[linkagepath,state['sequence'],
		state['newres'], state['anomer'], state['firstposition'],
		state['secondposition'], state['scale']]
	);
	state['refreshing'] = true;
	doXHR(this.builderURL,
		{ 	method: 'POST',
			sendContent: querystring,
			headers: {"Content-Type":"application/x-www-form-urlencoded"}
		}).addCallback(bind(this._replace_structure,this));
};

SugarBuilder.prototype._replace_structure = function(data) {
	state = this._state;
	
	mysvg = data.responseXML.childNodes[0].getElementsByTagName('div')[0].getElementsByTagName('div')[0];
	mysvg = mysvg.getElementsByTagNameNS('http://www.w3.org/2000/svg','svg')[0];
  svgdoc = document.importNode(mysvg,true);
	replaceChildNodes(this.build_elements['svg_canvas'],svgdoc);
	state['originalwidth'] = svgdoc.getAttribute('width');
	state['originalheight'] = svgdoc.getAttribute('height');
	state['svgdocument'] = svgdoc;
	this._state['ic_sequence'] = data.responseXML.childNodes[0].getElementsByTagName('div')[0].getElementsByTagName('div')[2].textContent;
	this.set_sequence(data.responseXML.childNodes[0].getElementsByTagName('div')[0].getElementsByTagName('div')[1].textContent);
	this._setupDropTargets();
	state['refreshing'] = false;
}

SugarBuilder.prototype._setupBuilder = function() {
	this._setupSvgCanvas();
	this._setupAnomerOverlay();
	this._setupLinkageOverlay();
	this._setupDraggingEvents();
	this._setupDropTargets();
	this._setupMiscEvents();
};
SugarBuilder.prototype._dragging = function(draggable,e) {
	state = this._state;
	state['mouse'] = e.mouse().page;
};
SugarBuilder.prototype._dragStart = function(draggable) {
	state = this._state;
	state['dragging'] = true;
	state['anomer'] = '';
	state['firstposn'] = '';
};

SugarBuilder.prototype._dragEnd = function(draggable) {
	state = this._state;
	state['dragging'] = false;
	
	if (state['current_target'] != null) {
		state['newres'] = draggable.element.getAttribute('alt');
		this.build_structure(state['current_target'].getAttribute('linkid'));
		this._restartParameterSetting();
	}
//	draggable.element.style.top = '0px';
//	draggable.element.style.left = '0px';	
};

SugarBuilder.prototype._svg_mouseclick = function(e) {
	state = this._state;
	if (state['mode'] == 'prune') {
		state['newres'] = 'prune';
		this.refresh_structure(e.target().getAttribute('linkid'));
	}
};


SugarBuilder.prototype._svg_mouseout = function(e) {
	state = this._state;
	if (! state['dragging']) {
		return;
	}

	if (this.build_elements['anomer_overlay'].cfg.getProperty('visible') ||
			this.build_elements['linkage_overlay'].cfg.getProperty('visible')) {
			return;
	}

	this._restartParameterSetting();
};

SugarBuilder.prototype._select_target = function(targ) {
	state = this._state;
	if (! state['dragging']) {
		return;
	}

	state['current_target'] = targ;
	targ.style.opacity = 0.2;
	this.build_elements['linkage_overlay'].cfg.setProperty('visible',false);	
	this.build_elements['anomer_overlay'].cfg.setProperty('visible',true);
	this.build_elements['anomer_overlay'].cfg.setProperty('xy',[state['mouse']['x']-50,state['mouse']['y']-50]);
};

SugarBuilder.prototype._select_linkage = function() {
	state = this._state;
	if (! state['dragging']) {
		return;
	}

	this.build_elements['anomer_overlay'].cfg.setProperty('visible',false);
	this.build_elements['linkage_overlay'].cfg.setProperty('visible',true);
	this.build_elements['linkage_overlay'].cfg.setProperty('xy',[state['mouse']['x']-50,state['mouse']['y']-50]);
}

SugarBuilder.prototype._acceptAnomer = function(anomer) {
	state = this._state;
	
	this.set_anomer(anomer);
	
	if (! state['dragging']) {
		return;
	}
	
	this._cancelEvents();
	
	this._select_linkage();
};

SugarBuilder.prototype._acceptLinkage = function(linkage) {
	state = this._state;
	els = getElementsByTagAndClassName(null,'sugarbuilder_link');
	linker = $('sugarbuilder_link_'+linkage); 
	for (var i = 0; i < els.length; i++ ) {
		els[i].setAttribute("style","fill: #dddddd; stroke: #000000; stroke-width: 1pt;");
		if (els[i] == linker) {
			els[i].setAttribute("style","fill: #ffffff; stroke: #000000; stroke-width: 1pt;");
		}
	}
	this.set_second_position(1);
	this.set_first_position(linkage);
};

SugarBuilder.prototype._cancelEvents = function() {
	state = this._state;
	if (state['currevent'] != null) {
		state['currevent'].cancel();
		state['currevent'] = null;
	}
	if (state['mouseStopped'] != null) {
		state['mouseStopped'].cancel();
		state['mouseStopped'] = null;
	}
}

SugarBuilder.prototype._restartParameterSetting = function(caller) {
	state = this._state;

	if (caller == "anomer" && ! this.build_elements['anomer_overlay'].cfg.getProperty('visible') ) {
		return;
	}

	if (caller == "link" && ! this.build_elements['anomer_overlay'].cfg.getProperty('visible') ) {
		return;
	}

	this._cancelEvents();

	if ( state['current_target'] != null ) {
		state['current_target'].style.opacity = 0;
	}

	this.build_elements['anomer_overlay'].cfg.setProperty('visible',false);
	this.build_elements['linkage_overlay'].cfg.setProperty('visible',false);
	state['newres'] = null;
	state['current_target'] = null;
};

SugarBuilder.prototype._setupDropTargets = function() {
	targets = XHtmlDOM.getElementsByClassName(this.opts['drop_target_class']);
	for ( var i in targets ) {
		connect(targets[i],'onmouseout', this, this._svg_mouseout);
		connect(targets[i],'onmousestop', this, partial(this._select_target,targets[i]));
		connect(targets[i],'onmousemove',this,partial(this._signalMouseStopped,0.2));
		connect(targets[i],'onclick', this, this._svg_mouseclick);
	}
};

SugarBuilder.prototype._setupDraggingEvents = function() {
	connect(Draggables, 'start', this, this._dragStart);
	connect(Draggables, 'drag', this, this._dragging);
	connect(Draggables, 'end', this, this._dragEnd);
};

SugarBuilder.prototype._setupMiscEvents = function() {
//	connect(this.build_elements['svg_canvas'],'onmouseout',this,this._restartParameterSetting);
	connect(this.build_elements['svg_canvas'],'onmouseover',this,this._restartParameterSetting);
};
