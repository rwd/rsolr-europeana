module RSolr
  module Europeana
    class Client < RSolr::Client
      def initialize(connection, options = {})
        options[:url] = 'http://www.europeana.eu/api/v2'
        super(connection, options)
      end
      
      def send_and_receive(path, opts)
        if (opts[:params][:qt] == "document") && opts[:params][:id]
          id = opts[:params].delete(:id)
          path = "/api/v2/record/#{id}.json"
        else
          path = "/api/v2/search.json"
          
          opts[:params][:query] = opts[:params].delete(:q)
          opts[:params][:profile] = "facets params"
          opts[:params][:facet] = opts[:params].delete("facet.field")
          opts[:params][:start] = (opts[:params][:start] || 0) + 1
          opts[:params][:qf] = (opts[:params].delete(:fq) || [])
          
          opts[:params].delete("facet.query") # @todo map to s'thing
          opts[:params].delete("facet.pivot") # @todo map to s'thing, or raise error if present
          opts[:params].delete(:sort) # @todo restore when API supports sort
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
          value.sub(/\A\{.*?=([^ \}]*).*?\}(.*)\Z/, '\1:\2')
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

        Rails.logger.debug("RSolr::Europeana::Client#build_request URI: #{opts[:uri].inspect}")
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
      
      def solrize_record_response(response)
        Rails.logger.debug("RSolr::Europeana::Client#evaluate_json_response object: #{response[:object].inspect}")
        obj = response[:object]
        doc = obj.reject do |key, value| 
          [ :aggregations, :proxies, :providedCHOs, :europeanaAggregation ].include?(key)
        end
        
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

        doc.each_pair do |key, value|
          if value.is_a?(Array)
            doc[key] = value.uniq
          elsif value.is_a?(Hash)
            if (value.length == 1) && value.has_key?(:def)
              doc[key] = doc[key][:def]
            elsif value.has_key?(:en)
              doc[key] = doc[key][:en]
            end
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
