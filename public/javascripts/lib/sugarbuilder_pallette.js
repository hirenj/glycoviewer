if ( typeof(SugarBuilder.Pallette) == undefined ) {
	SugarBuilder.Pallette = {};
}

SugarBuilder.Pallette = function(builderURL,opts) {
	if (opts) {
		if (opts['namespace']) {
			this._ns = opts['namespace'];
		}
	}
	this.builderURL = builderURL;
	this._canvas = XHtmlDOM.makeElement('div');
	appendChildNodes(this._canvas, XHtmlDOM.makeElement('div'));		
	this._setupPallette();

	screen_overlay = XHtmlDOM.makeElement('div');
	updateNodeAttributes(screen_overlay, { 'style' : 'position: absolute; top: -1px; left: -1px; width: 100%; height: 100%; background: #ffffff; border: solid #ffffff 1px; opacity: 0.85; display: none;', });

	this._screen = screen_overlay;

	appendChildNodes(this._canvas,screen_overlay);
}

SugarBuilder.Pallette.prototype.canvas = function() {
	return this._canvas;
}

SugarBuilder.Pallette.prototype.screenPallette = function() {
	appear(this._screen, { 'from': 0, 'to': 1.0 });	
}

SugarBuilder.Pallette.prototype.unScreenPallette = function() {
	fade(this._screen, { 'from': 0.9, 'to': 0 });
}

SugarBuilder.Pallette.prototype._setupPallette = function() {
	this._get_pallette();
}

SugarBuilder.Pallette.prototype._get_pallette = function() {
	var queryopts = {};
	if (this._ns) {
		queryopts['ns'] = this._ns;
	}
	querystring = queryString(queryopts);
	doXHR(this.builderURL,
		{ 	method: 'POST',
			sendContent: querystring,
			headers: {"Content-Type":"application/x-www-form-urlencoded"}
		}).addCallback(bind(this._accept_pallette,this));
};

SugarBuilder.Pallette.prototype._accept_pallette = function(data) {
	pallette = data.responseXML.childNodes[0].getElementsByTagName('img');
	imported_elements = [];
	for (var i = 0; i < pallette.length; i++) {
		imported_pal = document.importNode(pallette[i],true);
			
		a_drag = new Draggable(imported_pal, { revert : true, ghosting: false, zindex: 1, selectclass: 'draggable' });
		
		updateNodeAttributes(imported_pal, {'class' : 'pallette_element'});
		imported_elements.push(imported_pal);
	}
	insertSiblingNodesBefore(this._screen,imported_elements);
};

SugarBuilder.Slider = function() {
	this._setupSlider();
};

SugarBuilder.Slider.prototype.canvas = function() {
	return this._canvas;
};

SugarBuilder.Slider.prototype._setupSlider = function() {
	sliderContainer = XHtmlDOM.makeElement('div');
	sliderBar = XHtmlDOM.makeElement('div');
	appendChildNodes(sliderContainer, [ sliderBar ]);
	updateNodeAttributes(sliderBar,{ 'class' : 'sugarbuilder_slider_controller' });
	updateNodeAttributes(sliderContainer,{ 'class' : 'sugarbuilder_slider_container' });	
	
	this._element = YAHOO.widget.Slider.getVertSlider(sliderContainer, sliderBar, 100, 100);
	this._element.setValue(0);
 	this._element.subscribe("change", this._onchange, this);
	this._element.animate = false;
	this._canvas = sliderContainer;
};

SugarBuilder.Slider.prototype.target = function() {
	return this;
}

SugarBuilder.Slider.prototype.setScale = function(newValue) {
	slider.value = newValue;
	slider._element.setValue(100*(1 - newValue));
}

SugarBuilder.Slider.prototype._onchange = function(newValue, slider) {
	slider.value = 2 - ((100 + newValue) / 100.0);
	signal(slider,"onchange",slider);
};

