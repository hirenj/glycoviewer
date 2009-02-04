XHtmlDOM = {
	version: '$Id$',
	_set_class_name: function(el,clazz) {			
		if (el.className && el.className.constructor == document.SVGAnimatedString) {
			el.className.baseVal = clazz;
		} else if (el.className) {
			el.className = clazz;
		} else {
			curr_class = el.hasAttribute('class')  ? el.getAttribute('class') : '';
			el.setAttribute('class', clazz);					
		}
		return el;		
	},
	
	_get_class_name: function(el) {
		clazz = '';
		if (el.className && el.className.baseVal) {
			clazz = el.className.baseVal;
		} else if (el.className) {
			clazz = el.className;
		} else {
			clazz = el.hasAttribute('class')  ? el.getAttribute('class') : '';
		}
		return clazz;
	},
	
	_add_class: function(el, clazz) {
		class_string = " " + clazz + " ";			
		XHtmlDOM._set_class_name(el, XHtmlDOM._get_class_name(el) + class_string);
		return el;
	},
	
	_remove_class: function(el, clazz) {
		var curr_class = XHtmlDOM._get_class_name(el);
		var rep = curr_class.match(' '+clazz)? ' ' + clazz : clazz;
	  curr_class = curr_class.replace(rep,'');
		XHtmlDOM._set_class_name(el,curr_class);
		return el;
	},
	
	_ie_xpath_elements: function(node, expr) {
		return {
	    list: node.selectNodes(expr),
	    i : 0,
	    next: function() {
	      if (this.i > this.list.length)
	        return null;
	      return this.list[this.i++];
	    }
	  };
	},


	/*
		_ie_get_elements_by_classname adopted from online code:
		Written by Jonathan Snook, http://www.snook.ca/jonathan
		Add-ons by Robert Nyman, http://www.robertnyman.com
	*/

	_ie_get_elements_by_classname: function(oElm, strTagName, strClassName){
		var arrElements = (strTagName == "*" && oElm.all)? oElm.all : oElm.getElementsByTagName(strTagName);
		var arrReturnElements = new Array();
		strClassName = strClassName.replace(/\-/g, "\\-");
		var oRegExp = new RegExp("(^|\\s)" + strClassName + "(\\s|$)");
		var oElement;
		for(var i=0; i<arrElements.length; i++){
			oElement = arrElements[i];
			if(oRegExp.test(oElement.className)){
				arrReturnElements.push(oElement);
			}
		}
		return (arrReturnElements)
	},
	_run_xpath: function(xpath, element, doc) {
		results = [];
		if (doc.evaluate) {
			xpath_result = doc.evaluate(xpath,element,null,XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,null);
			var i = 0;
			while ( (a_result = xpath_result.snapshotItem(i)) != null ) {
				results.push(a_result);
				i++;
			}
		} else {
			xpath_result = element.selectNodes(xpath);
			for (var i = 0; i < xpath_result.length; i++ ){
				results[i] = xpath_result.item(i);
			}
		}
		return results;
	},
	
	_get_elements_by_classname: function(clazz, startnode) {
		startnode = $(startnode);
		var xpath = ".//*[contains(@class,'"+clazz+"')]";
		var results = [];
		if (document.evaluate) {
			var resultsnapshot = document.evaluate(xpath,startnode,null,XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);
			var i = 0;
			while ( (anode = resultsnapshot.snapshotItem(i)) != null ) {
				results.push(anode);
				i++;
			}		
		} else {
			results = XHtmlDOM._ie_get_elements_by_classname(startnode,"*",clazz);
		}
		return results;
	},

	addClass: function(el, clazz) {
		return XHtmlDOM._add_class(el,clazz);
	},

	removeClass: function(el, clazz) {
		return XHtmlDOM._remove_class(el,clazz);
	},

	makeElement: function(el) {
		if (document.createElementNS) {
			foo = document.createElementNS('http://www.w3.org/1999/xhtml',el);
		} else {
			foo = document.createElement(el);
		}
		return foo;
	},

	evaluateXPath: function(el, xpath, doc) {
		return XHtmlDOM._run_xpath(xpath,el,doc);
	},

	getElementsByClassName: function(clazz, startnode) {
		if (typeof(startnode) == 'undefined')
			startnode = document;

		return XHtmlDOM._get_elements_by_classname(clazz, startnode);
	}


};