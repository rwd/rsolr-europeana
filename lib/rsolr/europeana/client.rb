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
          opts[:params][:profile] = "facets"
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
        result = super
        
        if result[:object]
          solr_result = {
            'response' => {
              'numFound' => 1,
              'start' => 0,
              'docs' => [ result[:object] ]
            }
          }
        else
          facet_fields = (result[:facets] || []).inject({}) do |facet_fields, facet|
            facet_fields[facet[:name]] = facet[:fields].collect { |field| [ field[:label], field[:count] ] }.flatten
            facet_fields
          end
          
          solr_result = {
            'response' => {
              'numFound' => result[:totalResults],
              'start' => (request[:params]['start'] || 0) - 1,
              'docs' => result[:items],
            },
            'facet_counts' => {
              'facet_fields' => facet_fields
            }
          }
        end

        solr_result
      end
    end
  end
end
