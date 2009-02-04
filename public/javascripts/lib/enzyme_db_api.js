// Using POD format for documentation - plays nicely with JSAN.
// requires MochiKit 1.4+

EnzymeDbApi = {};

/*
=head1 EnzymeDbApi connector

Connector into the SOAP and REST interfaces provided by the EnzymeDb. This 
library will fetch a WSDL file with a set of SOAP ports defined, or will 
use hardcoded REST references to interface with the database. The interface 
will attempt to use a SOAP interface, and failing that use a REST interface
to interact with the database.

The L<initialize|/"EnzymeDbApi.initialize"> function is automatically called on 
the inclusion of this file, and sets up the available APIs/Ports which are listed 
L<below|/"Implemented Ports">.

=cut
*/
EnzymeDbApi = {
	/*
=over

=item EnzymeDbApi.initialize()

Initialize the EnzymeDbApi by reading WSDL and setting up Proxy objects. 
This function is automatically called upon inclusion of this JavaScript file.

=back

=cut
	*/
	initialize: function()
	{
		success = false;
		try {
			EnzymeDbApi._SoapImpl.initialize();
			success = true;
		} catch (ex) {
			log('Could not establish SOAP connection with server');
		}
		try {
			log('Trying to extablish REST connection');
			if (! success) {
				EnzymeDbApi._RestImpl.initialize();
			}
			log('REST connection established');
			success = true;
		} catch (ex) {
			log('Could not establish REST connection with server');			
		}
	},

	onError: function(aError)
	{
		log("An error has occured while processing the request: " + aError);
		throw new EnzymeDbApi.Exception('An error occurred while interfacing with the Enzyme Database');
	}
	
};

/*
=head2 Exceptions

=head3 EnzymeDbApi.Exception

Exception thrown by any API calls.

=cut
*/
EnzymeDbApi.Exception = function(message) {
	this.message = message;
	this.name = 'EnzymeDbApiException';
};

EnzymeDbApi._SoapImpl = {
	WSDL_URL:	EnzymeDbConstants.SOAP.WSDL,
	ENDPOINT: EnzymeDbConstants.SOAP.ENDPOINT,
	/* Have a go at loading up the SOAP interface using the Mozilla-only
		 WebServiceProxyFactory, but on any error, throw an exception.
		 The function doesn't try too hard to recover from errors.
	 */
	initialize:	function()
	{
		try {
			var factory = new WebServiceProxyFactory();
			for ( var i in this._ports() ) {
				factory.createProxyAsync(this.WSDL_URL, this._ports()[i].port(),"",true,this._ports()[i]);
			}
		} catch (ex) {
			throw EnzymeDbApi.Exception('Could not create SOAP interface '+ex);
		}
		return true;
	},
	
	_ports: function() {
		return [EnzymeDbApi.Geneinfo, EnzymeDbApi.EnzymeReaction];
	}

};

EnzymeDbApi._RestImpl = {
	/*
		Load up our available APIs.
	*/
	initialize: function()
	{
		EnzymeDbApi.Geneinfo.onLoad((new EnzymeDbApi._RestImpl.GeneinfoProxy()));
		EnzymeDbApi.EnzymeReaction.onLoad(new EnzymeDbApi._RestImpl.EnzymeReactionProxy());
	},
	/*
		A prototype class for the REST based proxy objects. Like the SOAP implementation,
		we'll want to use the setListener to set the object to apply callbacks to.
	*/
	proxyPrototype: function()
	{
		this.setListener = function(listener) {
			this.__listener__ = listener;
			return true;
		};
		this.getListener = function() {
			return this.__listener__;
		};
		this.dataReceived = function(callback, data) {
			callback.call(data);
		};
		this.getRequest = function(target) {
			request = getXMLHttpRequest();
			request.open('POST',target);
			request.setRequestHeader('Content-Type','application/xml');
			request.setRequestHeader('Accept','application/xml');
			return request;			
		};
	}
};

EnzymeDbApi._RestImpl.GeneinfoProxy = function() {
	
	this.AssociateProtein = function(gene_id, protein_id) {
		return null;
	};
	
	this.AssociateContext = function(gene_id, mesh_tissue, ncbi_taxonomy) {
		message = createDOM('enzymeinfo',null,
								createDOM('geneinfo-id',null,gene_id),
								createDOM('mesh-tissue',null,mesh_tissue),
								createDOM('record-class',null,'context'),
								createDOM('ncbi-taxonomy',null,ncbi_taxonomy)
							);
		request = this.getRequest(EnzymeDbConstants.REST['enzymeinfos'].create);
		deferred = sendXMLHttpRequest(request,toHTML(message));
		deferred.addCallback(partial(this.dataReceived,bind(this.getListener().AssociateContextCallback,this.getListener())));
		deferred.addErrback(EnzymeDbApi.onError);
	};
};

EnzymeDbApi._RestImpl.GeneinfoProxy.prototype = new EnzymeDbApi._RestImpl.proxyPrototype();


EnzymeDbApi._RestImpl.EnzymeReactionProxy = function() {

	this.AssociateEnzyme = function(reaction_id, enzyme_id) {
		message = createDOM('enzyme-reaction',null,createDOM('reaction-id',null,reaction_id),createDOM('enzymeinfo-id',null,enzyme_id));
		request = this.getRequest(EnzymeDbConstants.REST['enzyme_reactions'].create);
		deferred = sendXMLHttpRequest(request,toHTML(message));
		deferred.addCallback(partial(this.dataReceived,bind(this.getListener().AssociateEnzymeCallback,this.getListener())));
		deferred.addErrback(EnzymeDbApi.onError);
	};
	
	this.AssociateReference = function(enzyme_reaction_id,pmid) {
		message = createDOM('ref',null,createDOM('enzyme-reaction-id',null,enzyme_reaction_id),createDOM('pmid',null,pmid));
		request = this.getRequest(EnzymeDbConstants.REST['refs'].create);
		deferred = sendXMLHttpRequest(request,toHTML(message));
		deferred.addCallback(partial(this.dataReceived,bind(this.getListener().AssociateReferenceCallback,this.getListener())));
		deferred.addErrback(EnzymeDbApi.onError);		
	};
	
	this.Destroy = function(enzyme_reaction_id) {
		message = createDOM('enzyme-reaction',null,createDOM('id',null,enzyme_reaction_id));
		request = this.getRequest(EnzymeDbConstants.REST['enzyme_reactions'].destroy);
		deferred = sendXMLHttpRequest(request,toHTML(message));
		deferred.addCallback(partial(this.dataReceived,bind(this.getListener().DestroyCallback,this.getListener())));
		deferred.addErrback(EnzymeDbApi.onError);		
	};
	
};

EnzymeDbApi._RestImpl.EnzymeReactionProxy.prototype = new EnzymeDbApi._RestImpl.proxyPrototype();

/*
=head2 Ports

=head3 EnzymeDbApi.PortClass

Base class for implemented Ports. Implements a subset of the API, and provides
a location for storing the result.

Ports are not threadsafe - so don't go about starting multiple asynchronous
requests based upon these ports.

=over

=cut
*/
EnzymeDbApi.PortClass = {

	__proxy__: null,
/*
=item EnzymeDbApi.PortClass.onLoad(proxy)

Callback to set the proxy object for a port. Called by an API implementation 
such as REST or SOAP.

=cut
*/
	onLoad: function(proxy) {
		log(this);
		log(proxy.__class__);
		log(this.__proxy__);
		this.__proxy__ = proxy;
		this.__proxy__.setListener(this);
	},

/*
=item EnzymeDbApi.PortClass.onError

Uses the onError method of the EnzymeDbApi to handle errors

=cut
*/
	onError: EnzymeDbApi.onError,

	port: function() {
		return this.__port__;
	},
	
	proxy: function() {
		return this.__proxy__;
	},

};

/*
=back

=head3 Implemented Ports

=over

=item EnzymeDbApi.Geneinfo

Implementation of the Geneinfo API for the EnzymeDb.

=over
=cut
*/
EnzymeDbApi.Geneinfo = {

	__port__: 'EnzymeDbGeneinfoPort',

/*
=item EnzymeDbApi.Geneinfo.AssociateProtein(gene_id, protein_id)

Associate a protein with a particular Gene. Both protein and gene must 
already exist in the database.

Usage:

	connect(EnzymeDbApi.Geneinfo, 'AssociateProteinResult', function() { alert('Associated protein and gene'); });	
	EnzymeDbApi.Geneinfo.AssociateProtein(1,112);

=cut
*/

	AssociateProtein: function(gene_id, protein_id)
	{
		if ( ! this.proxy() ) {
			log("Proxy not initialized!");
			return;
		}
		this._associate_protein_callback_result = null;
		this.proxy().AssociateProtein(gene_id,protein_id);
		return;
	},

	AssociateProteinCallback: function(result)
	{
		this._associate_protein_callback_result = result;
		signal(this, 'AssociateProteinResult');
	},

	AssociateContext: function(gene_id, mesh_tissue, ncbi_taxonomy)
	{
		if ( ! this.proxy() ) {
			log("Proxy not initialized!");
			return;
		}
		this._associate_context_callback_result = null;
		this.proxy().AssociateContext(gene_id,mesh_tissue,ncbi_taxonomy);
		return;
	},

	AssociateContextCallback: function(result)
	{
		this._associate_context_callback_result = result;
		signal(this, 'AssociateContextResult');
	}

};

update(EnzymeDbApi.Geneinfo,EnzymeDbApi.PortClass);
/*
=back

=item EnzymeDbApi.EnzymeReaction

Implementation of the EnzymeReaction API for the EnzymeDb.

=over

=cut
*/
EnzymeDbApi.EnzymeReaction = {
	__port__: 'EnzymeDbEnzymeReactionPort',

/*
=item EnzymeDbApi.EnzymeReaction.AssociateEnzyme(reaction_id,enzyme_id)

Create an association between an Enzyme and a reaction in the database.

Usage

	connect(EnzymeDbApi.EnzymeReaction, 'AssociateEnzymeResult', function() { alert('Created an EnzymeReaction!'); });
	EnzymeDbApi.EnzymeReaction.AssociateEnzyme(1,112);

=cut
*/
	AssociateEnzyme: function(reaction_id,enzyme_id)
	{
		if ( ! this.proxy() ) {
			log("Proxy not initialized!");
			return;
		}
		this._associate_enzyme_result = null;
		this.proxy().AssociateEnzyme(reaction_id, enzyme_id);
		return;
	},

	AssociateEnzymeCallback: function(result)
	{
		this._associate_enzyme_result = result;
		signal(this, 'AssociateEnzymeResult');
	},

	AssociateReference: function(enzyme_reaction_id, pubmed_id)
	{
		if ( ! this.proxy() ) {
			log("Proxy not initialized!");
			return;
		}
		this._associate_reference_result = null;
		this.proxy().AssociateReference(enzyme_reaction_id, pubmed_id);
	},

	AssociateReferenceCallback: function(result)
	{
		this._associate_reference_result = result;
		signal(this,'AssociateReferenceResult');
	},
	
	Destroy: function(enzyme_reaction_id)
	{
		if ( ! this.proxy() ) {
			log("Proxy not initialized!");
			return;
		}
		this._associate_reference_result = null;
		this.proxy().Destroy(enzyme_reaction_id);
	},

	DestroyCallback: function(result)
	{
		this._destroy_result = result;
		signal(this,'DestroyResult');
	},

}

update(EnzymeDbApi.EnzymeReaction,EnzymeDbApi.PortClass);

EnzymeDbApi.initialize();