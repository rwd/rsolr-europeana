module RSolr
  module Europeana
    class Client < RSolr::Client
      def initialize(connection, options = {})
        options[:url] = 'http://www.europeana.eu/api/v2'
        super(connection, options)
      end
      
      def send_and_receive(path, opts)
        RSolr::Europeana.logger.debug("RSolr::Europeana::Client#send_and_receive path: #{path}")
        RSolr::Europeana.logger.debug("RSolr::Europeana::Client#send_and_receive opts: #{opts.inspect}")
        
        if (opts[:params][:qt] == "document") && opts[:params][:id]
          id = opts[:params].delete(:id)
          path = "/api/v2/record/#{id}.json"
        elsif opts[:params][:q].blank?
          return fake_empty_search_response
        else
          path = "/api/v2/search.json"
          
          opts[:params][:query] = opts[:params].delete(:q)
          opts[:params][:profile] = "facets params"
          opts[:params][:facet] = opts[:params].delete("facet.field")
          opts[:params][:start] = (opts[:params][:start] || 0) + 1
          opts[:params][:qf] = (opts[:params].delete(:fq) || [])
          
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
        
        super(path, opts)
      end
      
      def rewrite_solr_local_params!(local_params = {})
        local_params.each_pair do |name, value|
          local_params[name] = rewrite_solr_local_param(name, value)
        end
      end
      protected :rewrite_solr_local_params!
      
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
      protected :rewrite_solr_local_param
      
      def build_request(path, opts)
        opts = super
        opts[:params][:wt] = "json"
        if opts[:path].match(/search\.json/) && opts[:params]["query"].to_s.empty?
          opts[:query] << '&query='
          opts[:uri].query << '&query='
        end

        RSolr::Europeana.logger.debug("Europeana API request URL: #{opts[:uri].to_s}")
        opts
      end
      
      def evaluate_json_response(request, response)
        evaluated_response = super
        
        if evaluated_response[:object]
          solrize_record_response(evaluated_response)
        else
          solrize_search_response(evaluated_response)
        end
      end
      
      def fake_empty_search_response
        {
          'response' => {
            'numFound' => 0,
            'start' => 0,
            'docs' => [ ]
          }
        }
      end
      
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
