if ( typeof(SugarBuilder.Pallette) == undefined ) {
	SugarBuilder.Pallette = {};
}

SugarBuilder.Pallette = function(builderURL) {
	this.builderURL = builderURL;
	this._canvas = XHtmlDOM.makeElement('div');
	appendChildNodes(this._canvas, XHtmlDOM.makeElement('div'));
	this._setupPallette();
}

SugarBuilder.Pallette.prototype.canvas = function() {
	return this._canvas;
}

SugarBuilder.Pallette.prototype._setupPallette = function() {
	this._get_pallette();
}

SugarBuilder.Pallette.prototype._get_pallette = function() {
	doXHR(this.builderURL,
		{ 	method: 'POST',
			headers: {"Content-Type":"application/x-www-form-urlencoded"}
		}).addCallback(bind(this._accept_pallette,this));
};

SugarBuilder.Pallette.prototype._accept_pallette = function(data) {
	pallette = data.responseXML.childNodes[0].getElementsByTagName('img');
	imported_elements = [];
	for (var i = 0; i < pallette.length; i++) {
		imported_pal = document.importNode(pallette[i],true);
		new Draggable(imported_pal, { revert : true, ghosting: false, zindex: -1 });
		updateNodeAttributes(imported_pal, {'class' : 'pallette_element'});
		imported_elements.push(imported_pal);
	}
	appendChildNodes(this._canvas,imported_elements);
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

SugarBuilder.Slider.prototype._onchange = function(newValue, slider) {
	slider.value = 2 - ((100 + newValue) / 100.0);
	signal(slider,"onchange",slider);
};

