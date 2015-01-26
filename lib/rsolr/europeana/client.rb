module RSolr
  module Europeana
    class Client < RSolr::Client
      def initialize(connection, options = {})
        options[:url] = 'http://www.europeana.eu/api/v2'
        super(connection, options)
      end
      
      def execute(request_context)
        if request_context[:params]["query"].nil? && request_context[:path].match(/\/search\.json/)
          fake_empty_search_response
        else
          RSolr::Europeana.logger.debug("Europeana API request URL: #{request_context[:uri].to_s}")
          super
        end
      end
      
      def build_request(path, opts)
        path, opts = adapt_request_for_api(path, opts)
        self.class.default_wt = "json"
        super(path, opts)
      end
      
      def adapt_response(request, response)
        result = super
        result[:object] ? solrize_record_response(result) : solrize_search_response(result)
      end
      
    protected
      
      def adapt_request_for_api(path, opts)
        if (opts[:params][:qt] == "document") && opts[:params][:id]
          id = opts[:params].delete(:id)
          path = "/api/v2/record/#{id}.json"
        else
          path = "/api/v2/search.json"
          
          opts[:params][:query] = opts[:params].delete(:q) unless opts[:params][:q].blank?
          opts[:params][:profile] = "facets params"
          opts[:params][:facet] = opts[:params].delete("facet.field")
          opts[:params][:start] = (opts[:params][:start] || 0) + 1
          opts[:params][:qf] = opts[:params].delete(:fq) unless opts[:params][:fq].blank?
          
          # Remove params unsupported by the API
          # @todo implement in the API / map to s'thing else / raise error if present
          opts[:params].delete("spellcheck.q")
          opts[:params].delete("facet.query")
          opts[:params].delete("facet.pivot")
          opts[:params].delete(:sort)
        end
        opts[:params].delete(:qt)
        opts[:params].delete(:wt)
        opts[:params][:wskey] = @options[:api_key]
        rewrite_solr_local_params!(opts[:params])
        
        return path, opts
      end
      
      def rewrite_solr_local_params!(local_params = {})
        local_params.each_pair do |name, value|
          local_params[name] = rewrite_solr_local_param(name, value)
        end
      end
      
      def rewrite_solr_local_param(name, value)
        case value
        when NilClass, Fixnum
          value
        when String
          if name == "query"
            value.sub(/\A\{.*?=([^ \}]*).*?\}(.*)\Z/, '\1:\2')
          else
            value.sub(/\A\{.*?=([^ \}]*).*?\}(.*)\Z/, '\1:"\2"')
          end
        when Array
          value.collect { |one| rewrite_solr_local_param(name, one) }
        else
          raise ArgumentError, "Unexpected param type: #{value.class.to_s}"
        end
      end
      
      ##
      # Constructs a pseudo-response as would be returned by a query to Solr 
      # with no results.
      #
      # Used by #send_and_receive if no query terms are present in a search
      # query.
      #
      # @return [Hash]
      def fake_empty_search_response
        {
          'response' => {
            'numFound' => 0,
            'start' => 0,
            'docs' => [ ]
          }
        }
      end
      
      ##
      # Adapts a response from the API's Record method to resemble a Solr
      # query response of one document.
      #
      # @param [Hash] response The Europeana REST API response
      # @return [Hash]
      def solrize_record_response(response)
        obj = response[:object]
        
        doc = obj.select do |key, value|
          [ :edmDatasetName, :language, :type, :title, :about, 
            :europeanaCollectionName, :timestamp_created_epoch,
            :timestamp_update_epoch, :timestamp_created, :timestamp_update ].include?(key)
        end
        
        doc[:id] = obj[:about]
        
        proxy = obj[:proxies].first.reject do |key, value|
          [ :proxyFor, :europeanaProxy, :proxyIn, :about ].include?(key)
        end
        
        aggregation = obj[:aggregations].first.reject do |key, value|
          [ :webResources, :aggregatedCHO, :about ].include?(key)
        end
        
        eaggregation = obj[:europeanaAggregation].reject do |key, value|
          [ :about, :aggregatedCHO ].include?(key)
        end
        
        doc.merge!(proxy).merge!(aggregation).merge!(eaggregation)
        
        doc.dup.each_pair do |key, value|
          if value.is_a?(Array)
            doc[key] = value.uniq
          elsif value.is_a?(Hash)
            if value.has_key?(:def)
              value.each_pair do |lang, labels|
                doc["#{key}_#{lang}"] = labels
              end
            end
            doc.delete(key)
          end
        end
        
        {
          'response' => {
            'numFound' => 1,
            'start' => 0,
            'docs' => [ doc ]
          }
        }
      end
      
      ##
      # Adapts a response from the API's Search method to resemble a Solr
      # query response.
      #
      # @param [Hash] response The Europeana REST API response
      # @return [Hash]
      def solrize_search_response(response)
        facet_fields = (response[:facets] || []).inject({}) do |facet_fields, facet|
          facet_fields[facet[:name]] = facet[:fields].collect { |field| [ field[:label], field[:count] ] }.flatten
          facet_fields
        end
        
        {
          'response' => {
            'numFound' => response[:totalResults],
            'start' => (response[:params][:start] || 0) - 1,
            'docs' => response[:items],
          },
          'facet_counts' => {
            'facet_fields' => facet_fields
          }
        }
      end
    end
  end
end
