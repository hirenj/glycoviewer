
if ( typeof(ECDB) == 'undefined' ) {
	ECDB = {};
}

if ( typeof(ECDB.SugarBuilderWidget) == 'undefined' ) {
	ECDB.SugarBuilderWidget = {};
}

ECDB.SugarBuilderWidget = function(target_element) {
	var pal = new SugarBuilder.Pallette(ECDB.SugarBuilderWidget.PALETTE_URL,{ 'namespace': 'ic' });
	var palette_element = new YAHOO.widget.Panel('mono-palette', {
		width:"400px",
		close:false, 
		visible:true,
		zindex: 2,
		underlay:'none',
		draggable:true} );
	palette_element.setHeader("Donors (drag and drop to add)");
	palette_element.setBody(pal.canvas());
	connect(Draggables,'start',partial(ECDB.SugarBuilderWidget._demotePanel,palette_element,pal));
	connect(Draggables,'end',partial(ECDB.SugarBuilderWidget._promotePanel,palette_element,pal));

	var sb = new SugarBuilder(ECDB.SugarBuilderWidget.BUILDER_URL,target_element.value);
	sb.set_namespace('ic');
	connect(sb,'sequencechange',partial(ECDB.SugarBuilderWidget._updateSeqs,target_element,sb));
	sb.refresh_structure('null');
	
	connect(target_element,"onblur",function() { sb.set_sequence(target_element.value); sb.refresh_structure('null'); });
	
	var widget = DIV();
	appendChildNodes(widget,sb.canvas());
	
	var slider = new SugarBuilder.Slider();
	slider.canvas().style.zIndex = 2;
	appendChildNodes(widget,slider.canvas());
		
	connect(sb,'sequencechange',sb,partial(ECDB.SugarBuilderWidget._updateScale,slider));

	palette_element.render(widget);
	palette_element.element.style.position = 'absolute';
	palette_element.element.style.top = '0px';
	palette_element.element.style.left = '50%';
	

	widget.onmousedown = function() { return false; }
	
	connect(document,'onkeydown',sb,partial(ECDB.SugarBuilderWidget._triggerPrune,true));
	connect(document,'onkeyup',sb,partial(ECDB.SugarBuilderWidget._triggerPrune,false));	
	
	connect(slider,'onchange',sb,partial(ECDB.SugarBuilderWidget._updateScale,slider));

    widget.builder = sb;

	return widget;
};

ECDB.SugarBuilderWidget.PALETTE_URL = '';
ECDB.SugarBuilderWidget.BUILDER_URL = '';

ECDB.SugarBuilderWidget._demotePanel = function(apanel,pal) {
	apanel.cfg.setProperty('zindex',-1);
	pal.screenPallette();
};

ECDB.SugarBuilderWidget._promotePanel = function(apanel,pal) {
	apanel.cfg.setProperty('zindex',2);
	pal.unScreenPallette();
};

ECDB.SugarBuilderWidget._triggerPrune = function(start,e) {
	if (e.modifier()['alt']) {
		this.set_prune_mode(start);
	} else {
		this.set_prune_mode(start);
	}
};

ECDB.SugarBuilderWidget._updateScale = function(slider) {
	var state = this._state;
	if (state['svgdocument']) {
		state['svgdocument'].setAttribute('width', state['originalwidth']*slider.value);
		state['svgdocument'].setAttribute('height', state['originalheight']*slider.value);
	}
};

ECDB.SugarBuilderWidget._updateSeqs = function(target,sb) {
	target.value = sb.get_sequence();
	signal(target,"onchange");
};
