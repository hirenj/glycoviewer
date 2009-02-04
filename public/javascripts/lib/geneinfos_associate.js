// Using POD format for documentation - plays nicely with JSAN.
// requires MochiKit 1.4+
// requires EnzymeDbApi

GeneinfosAssociate = {
	new_enzymes_callback: function(enzyme_id) {
		var url = EnzymeDbConstants.RESOURCES.REACTION_THUMBS+enzyme_id;
		var deferred = doSimpleXMLHttpRequest(url);
		deferred.addCallback(partial(GeneinfosAssociate.render_thumbs,enzyme_id));
	},
	
	new_expression_callback: function(geneinfo_id) {
		var url = EnzymeDbConstants.RESOURCES.TISSUE_EXPRESSION+geneinfo_id;
		var deferred = doSimpleXMLHttpRequest(url);
		log(url);
		log(deferred);
		deferred.addCallback(partial(GeneinfosAssociate.render_expression,geneinfo_id));
	},
	
	render_thumbs: function(enzyme_id, data) {
		enzyme_list = $('reaction_list_enzyme-'+enzyme_id);
		enzyme_list.innerHTML = data.responseText;
		GeneinfosAssociate.enable_pmid_adding(enzyme_list);
		GeneinfosAssociate.enable_enz_reac_deleting(enzyme_list);
	},
	
	render_expression: function(geneinfo_id, data) {
		current_expression = $('expression_gene-'+geneinfo_id);
		current_expression.innerHTML = data.responseText;
	},
	
	enable_draggables: function() {
		reactions = MochiKit.DOM.getElementsByTagAndClassName(null,'reaction');
		for ( var i in reactions ) {
			new Draggable(reactions[i], {
				revert: true,
				handle: reactions[i].getElementsByTagName('object')[0],
				selectclass: 'moving-reaction',
				scroll: $('enzymes')
			});
		}
	},
	
	enable_droptargets: function() {
		enzymes = MochiKit.DOM.getElementsByTagAndClassName(null,'enzyme');
		for ( var i in enzymes ) {
			new Droppable(enzymes[i],
				{
					target: enzymes[i],
					accept: ['reaction'],
					ondrop: function(element) {
						enzyme = this.target;
						reaction_id = element.id.split('-')[1];
						enzyme_id = enzyme.id.split('-')[1];
						disconnectAll(EnzymeDbApi.EnzymeReaction, 'AssociateEnzymeResult');
						connect(EnzymeDbApi.EnzymeReaction, 'AssociateEnzymeResult', partial(GeneinfosAssociate.new_enzymes_callback,enzyme_id));
						EnzymeDbApi.EnzymeReaction.AssociateEnzyme(reaction_id,enzyme_id);
					}
				}
			);
		}
	},
	
	fix_overflow_css: function() {
		enzyme_drag_start = function(el) {
			el.element.style.position = 'fixed';
			var additionalOffset = 0;
			if ($('enzymelist').scrollTop > 0) {
				additionalOffset = 50;
			}
			el.offset[1] = el.offset[1] + $('enzymelist').scrollTop + additionalOffset;
			$('enzymelist').style.overflow = 'visible';
		};
		enzyme_drag_stop = function(el) {
			el.element.style.position = 'relative';
			$('enzymelist').style.overflow = 'auto';
		};

		connect(Draggables,'start',enzyme_drag_start);
		connect(Draggables,'end',enzyme_drag_stop);
	},
	
	enable_pmid_adding: function(startnode) {
		if (startnode == null) {
			startnode = document;
		}
		pmid_inputs = MochiKit.DOM.getElementsByTagAndClassName('input','refs.pmid',startnode);
		for (var i in pmid_inputs) {
			pmid_input = pmid_inputs[i];
			enz_reac_id = /refs\.enzyme-reaction-id-(\d+)/.exec(pmid_input.className)[1];
			enz_id = /enzymeinfo\.id-(\d+)/.exec(pmid_input.parentNode.parentNode.parentNode.className)[1];
			connect(pmid_input, 'onkeyup', partial(GeneinfosAssociate._add_pmid,enz_reac_id, enz_id));
		}
	},
	
	_add_pmid: function(enz_reac_id, enzyme_id, event) {
		if(event.key().string == 'KEY_ENTER') {
			disconnectAll(EnzymeDbApi.EnzymeReaction, 'AssociateReferenceResult');
			connect(EnzymeDbApi.EnzymeReaction, 'AssociateReferenceResult', partial(GeneinfosAssociate.new_enzymes_callback,enzyme_id));
  		EnzymeDbApi.EnzymeReaction.AssociateReference(enz_reac_id,this.value);
		}
	},
	
	enable_enz_reac_deleting: function(startnode) {
		if (startnode == null) {
			startnode = document;
		}
		delete_divs = MochiKit.DOM.getElementsByTagAndClassName('div','del-enz-reac',startnode);
		for (var i in delete_divs) {
			delete_div = delete_divs[i];
			enz_reac_id = /del-id-(\d+)/.exec(delete_div.className)[1];
			enz_id = /enzymeinfo\.id-(\d+)/.exec(delete_div.parentNode.parentNode.className)[1];
			connect(delete_div, 'onclick', partial(GeneinfosAssociate._delete_enz_reac,enz_reac_id, enz_id));
		}
	},
	
	_delete_enz_reac: function(enz_reac_id,enzyme_id) {
		disconnectAll(EnzymeDbApi.EnzymeReaction, 'DestroyResult');
		connect(EnzymeDbApi.EnzymeReaction, 'DestroyResult', partial(GeneinfosAssociate.new_enzymes_callback,enzyme_id));
		EnzymeDbApi.EnzymeReaction.Destroy(enz_reac_id);
	},
	
	enable_context_adding: function(startnode) {
		if (startnode == null) {
			startnode = document;
		}
		input_fields = MochiKit.DOM.getElementsByTagAndClassName('input','input_button_add_context',startnode);
		for (var i in input_fields) {
			input_field = input_fields[i];
			mesh_tissue_element = MochiKit.DOM.getElementsByTagAndClassName('input', 'input_mesh_tissue', input_field.parentNode)[0];
			ncbi_taxonomy_element = MochiKit.DOM.getElementsByTagAndClassName('input', 'input_ncbi_taxonomy', input_field.parentNode)[0];
			connect(input_fields[i], 'onclick', partial(GeneinfosAssociate._add_context, $('gene_id').value, mesh_tissue_element, ncbi_taxonomy_element));
		}
	},
	
	_add_context: function(gene_id, mesh_tissue_element, ncbi_taxonomy_element) {
		disconnectAll(EnzymeDbApi.Geneinfo, 'AssociateContextResult');
		connect(EnzymeDbApi.Geneinfo, 'AssociateContextResult', partial(GeneinfosAssociate.new_expression_callback,gene_id));
		EnzymeDbApi.Geneinfo.AssociateContext(gene_id,mesh_tissue_element.value,ncbi_taxonomy_element.value);		
	}
	
};

connect(window, 'onload',
function() {
	
	GeneinfosAssociate.enable_draggables();
	GeneinfosAssociate.enable_droptargets();
	GeneinfosAssociate.fix_overflow_css();
	GeneinfosAssociate.enable_pmid_adding();
	GeneinfosAssociate.enable_enz_reac_deleting();
	GeneinfosAssociate.enable_context_adding();
	MochiKit.Position.includeScrollOffsets = true;
});

