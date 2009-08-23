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
						'in_drag' 			: false,
						'last_draggable'	: null,
						'sequence'			: '',
						'scale'				: 1,
						'anomer'			: null,
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
	var state = this._state;
	if (state['mouseStopped']) {
		state['mouseStopped'].cancel();
		state['mouseStopped'] = null;
	}
	state['mouseStopped'] = callLater(delay,bind(this._fireMouseStopped,this),e);
};

SugarBuilder.prototype._fireMouseStopped = function(e) {
	var state = this._state;
	state['mouseStopped'] = null;
	signal(e.target(),'onmousestop');
};


SugarBuilder.prototype._setupAnomerOverlay = function() {
	var anomer_names = { 'a': 'α','u':'?','b':'β'};
	var anomers = DIV({'class':'sugarbuilder_anomers'});

	this._setupWedges(	anomer_names,
						anomers,
						function(arc,arc_back,label) {
							connect(arc,'onmousestop',this,partial(this._acceptAnomer,label));
							connect(arc,'onmousemove',this,partial(this._signalMouseStopped,0.4));							
						}
					);

	var anomer_overlay = new YAHOO.widget.Overlay(anomers);
	anomer_overlay.cfg.setProperty("visible",false);
	anomer_overlay.cfg.setProperty("width", '105px');
	anomer_overlay.cfg.setProperty("height",'105px');
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
}

SugarBuilder.prototype._setupWedges = function(labels,container,wedge_callback,large_arc_size,small_arc_size) {
	var total_size = 0;
	for (var i in labels) {
		total_size = total_size + 1;
	}
	
	var LARGE_ARC_SIZE = large_arc_size ? large_arc_size : 50;
	var SMALL_ARC_SIZE = small_arc_size ? small_arc_size : 10;
	
	var last_x = LARGE_ARC_SIZE;
	var last_y = 0;
	var last_x2 = LARGE_ARC_SIZE;
	var last_y2 = LARGE_ARC_SIZE - SMALL_ARC_SIZE;
	var counter = 0;
	var pie_svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
	pie_svg.setAttribute('width','100');
	pie_svg.setAttribute('height','100');
	pie_svg.setAttribute('viewBox','-1 -1 102 102');
	var pie_labels = document.createElementNS('http://www.w3.org/2000/svg','g');
	var pie_backs = document.createElementNS('http://www.w3.org/2000/svg','g');

	appendChildNodes(pie_svg,pie_backs);
	appendChildNodes(pie_svg,pie_labels);

	for (var i in labels) {
		counter = counter + 1;
		var xpos = LARGE_ARC_SIZE + LARGE_ARC_SIZE * Math.cos(Math.PI*(2*counter / total_size + 0.5));
		var ypos = LARGE_ARC_SIZE - LARGE_ARC_SIZE * Math.sin(Math.PI*(2*counter / total_size + 0.5));
		var xpos2 = LARGE_ARC_SIZE + SMALL_ARC_SIZE * Math.cos(Math.PI*(2*counter / total_size + 0.5));
		var ypos2 = LARGE_ARC_SIZE - SMALL_ARC_SIZE * Math.sin(Math.PI*(2*counter / total_size + 0.5));

		var arc_string = "M"+last_x+","+last_y+" A"+LARGE_ARC_SIZE+","+LARGE_ARC_SIZE+" 0 0,0 "+xpos+","+ypos+" L"+xpos2+","+ypos2+" A"+SMALL_ARC_SIZE+","+SMALL_ARC_SIZE+" 0 0,1 "+last_x2+","+last_y2+" Z"

		var arc = document.createElementNS('http://www.w3.org/2000/svg','path');
		arc.setAttribute('d',arc_string);
		arc.setAttribute('style','opacity: 0.1; fill: #ffffff; stroke: none; stroke-width: 0;');
		
		var arc_back = document.createElementNS('http://www.w3.org/2000/svg','path');
		arc_back.setAttribute('d',arc_string);
		arc_back.setAttribute('class', 'pie_slice');
		arc_back.setAttribute('style','opacity: 1; fill: #dddddd; stroke: black; stroke-width: 1;');
		
		bind(wedge_callback,this)(arc,arc_back,i);
		
		var arc_label = document.createElementNS('http://www.w3.org/2000/svg','text');
		var label_xpos = LARGE_ARC_SIZE + (SMALL_ARC_SIZE + 0.5*(LARGE_ARC_SIZE - SMALL_ARC_SIZE)) * Math.cos(Math.PI * ( 0.5 + (2*counter - 1) / total_size ));
		var label_ypos = LARGE_ARC_SIZE - (SMALL_ARC_SIZE + 0.5*(LARGE_ARC_SIZE - SMALL_ARC_SIZE)) * Math.sin(Math.PI * ( 0.5 + (2*counter - 1) / total_size ));
		
		arc_label.setAttribute('x',label_xpos);
		arc_label.setAttribute('y',label_ypos+10);
		appendChildNodes(arc_label,document.createTextNode(labels[i]));
		arc_label.setAttribute('font-family', 'Helvetica');
		arc_label.setAttribute('text-anchor','middle');
		arc_label.setAttribute('font-size','25');
		arc_label.setAttribute('fill','#000000');

		appendChildNodes(pie_svg,arc);
		appendChildNodes(pie_labels,arc_label);
		appendChildNodes(pie_backs,arc_back);

		last_x = xpos;
		last_y = ypos;
		last_x2 = xpos2;
		last_y2 = ypos2;
	}

	appendChildNodes(container,pie_svg);

};

SugarBuilder.prototype._setupLinkageOverlay = function() {
	var link_names = {'2':2,'3':3,'4':4,'5':5,'6':6,'?':'?'};
	var links = DIV({'class':'sugarbuilder_linkages'});
	this._setupWedges(	link_names,
						links,
						function(arc,arc_back,label) {
							arc_back.setAttribute('class','link_pie_slice pie_slice sugarbuilder_link sugarbuilder_link_'+label);
							arc_back.setAttribute('id','sugarbuilder_link_'+label);
							connect(arc,'onmousestop',this,partial(this._acceptLinkage,label));
							connect(arc,'onmousemove',this,partial(this._signalMouseStopped,0));
						},
						50,1
					);
					
	connect(links,'onmouseout',this,
		function(e) {
			link_els = e.target().getElementsByTagName('div');
			for (var i = 0 ; i < link_els.length; i++) {
				if (e.relatedTarget() == link_els[i]) {					
					return;
				}
				this._restartParameterSetting("link");
			}
		});

	var link_overlay = new YAHOO.widget.Overlay(links);
	link_overlay.cfg.setProperty("visible",false);
	link_overlay.cfg.setProperty("width", '105px');
	link_overlay.cfg.setProperty("height",'105px');
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
	var old_sequence = this._state['sequence'];
	this._state['sequence'] = sequence;
	if (old_sequence != sequence) {
		signal(this,'sequencechange');
	}
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

SugarBuilder.prototype.set_namespace = function(ns) {
	this._state['ns'] = ns;
}

SugarBuilder.prototype.canvas = function() {
	return this.build_elements['svg_canvas'];
}

SugarBuilder.prototype.set_prune_mode = function(prunemode) {
	this._state['mode'] = prunemode ? 'prune' : 'build';
}

SugarBuilder.prototype.build_structure = function(linkagepath) {
	var state = this._state;
	if (linkagepath == null) {
		return;
	}
	if (state['newres'].match(/neu/)) {
		this.set_second_position(2);
	}
	
	this.refresh_structure(linkagepath);
};

SugarBuilder.prototype.refresh_structure = function(linkagepath) {
	var state = this._state;
	var queryopts = {
		"identifier": linkagepath,
		"seq": state['sequence'],
		"newresidue": state['newres'],
		"anomer": state['anomer'],
		"firstposn": state['firstposition'],
		"secondposn": state['secondposition'],
		"scale": state['scale'],
		};
	if (state['ns']) {
		queryopts['ns'] = state['ns'];
	}
	var querystring = queryString(queryopts);
	state['refreshing'] = true;
	doXHR(this.builderURL,
		{ 	method: 'POST',
			sendContent: querystring,
			headers: {"Content-Type":"application/x-www-form-urlencoded"}
		}).addCallback(bind(this._replace_structure,this));
};

SugarBuilder.prototype._replace_structure = function(data) {
	var state = this._state;
	
	var mysvg = data.responseXML.childNodes[0].getElementsByTagName('div')[0].getElementsByTagName('div')[0];
	mysvg = mysvg.getElementsByTagNameNS('http://www.w3.org/2000/svg','svg')[0];
  	var svgdoc = document.importNode(mysvg,true);
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
	var state = this._state;
	state['mouse'] = e.mouse().page;
};
SugarBuilder.prototype._dragStart = function(draggable) {
	var state = this._state;
	state['dragging'] = true;
	state['anomer'] = '';
	state['firstposn'] = '';
};

SugarBuilder.prototype._dragEnd = function(draggable) {
	var state = this._state;
	state['dragging'] = false;
	
	if (state['current_target'] != null) {
		state['newres'] = draggable.element.getAttribute('alt');
		this.build_structure(state['current_target'].getAttribute('linkid'));
		this._restartParameterSetting();
	} else {
		if (this.get_sequence() == '') {
			state['newres'] = draggable.element.getAttribute('alt');
			this.refresh_structure('null');
		}
	}
};

SugarBuilder.prototype._svg_mouseclick = function(e) {
	var state = this._state;
	if (state['mode'] == 'prune') {
		state['newres'] = 'prune';
		this.refresh_structure(e.target().getAttribute('linkid'));
	}
};


SugarBuilder.prototype._svg_mouseout = function(e) {
	var state = this._state;
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
	var state = this._state;
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
	var state = this._state;
	if (! state['dragging']) {
		return;
	}

	this.build_elements['anomer_overlay'].cfg.setProperty('visible',false);
	this.build_elements['linkage_overlay'].cfg.setProperty('visible',true);
	this.build_elements['linkage_overlay'].cfg.setProperty('xy',[state['mouse']['x']-50,state['mouse']['y']-50]);
}

SugarBuilder.prototype._acceptAnomer = function(anomer) {
	var state = this._state;
	
	this.set_anomer(anomer);
	
	if (! state['dragging']) {
		return;
	}
	
	this._cancelEvents();
	
	this._select_linkage();
};

SugarBuilder.prototype._acceptLinkage = function(linkage) {
	var state = this._state;
	var els = getElementsByTagAndClassName(null,'sugarbuilder_link');
	var linker = $('sugarbuilder_link_'+linkage); 
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
	var state = this._state;
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
	var state = this._state;

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
	var targets = XHtmlDOM.getElementsByClassName(this.opts['drop_target_class']);
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
	connect(this.build_elements['svg_canvas'],'onmouseover',this,this._restartParameterSetting);
};
