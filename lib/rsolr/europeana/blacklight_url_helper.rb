module RSolr::Europeana::BlacklightUrlHelper
  def url_for_document doc, options = {}
    # @optimize: 
    #   if doc.to_model.is_a? EuropeanaRecord
    if doc.respond_to?(:provider_id) and doc.respond_to?(:record_id)
      solr_document_path(provider_id: doc.provider_id, record_id: doc.record_id)
    else
      super
    end
  end

  # @todo: un-hard-code "catalog"
  def track_solr_document_path doc, options = {}
    url_for(options.merge(controller: "catalog", action: :track, provider_id: doc.provider_id, record_id: doc.record_id))
  end
  
  def link_to_previous_document(previous_document)
    link_opts = session_tracking_params(previous_document, search_session['counter'].to_i - 1).merge(:class => "previous", :rel => 'prev')
    link_to_unless previous_document.nil?, raw(t('views.pagination.previous')), url_for_document(previous_document), link_opts do
      content_tag :span, raw(t('views.pagination.previous')), :class => 'previous'
    end
  end
end
