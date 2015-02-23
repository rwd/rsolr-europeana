module RSolr
  module Europeana
    module RequestRewriter
      ##
      # Search request rewriter
      class Search < Base
        def path
          '/api/v2/search.json'
        end

        def rewrite_params
          @params[:query] = @params.delete(:q)
          @params[:query] = '*:*' if @params[:query] == '{!qf=all_fields}'
          @params[:profile] = 'facets params'
          @params[:facet] = @params.delete('facet.field')
          @params[:start] = (@params[:start] || 0) + 1
          @params[:qf] = @params.delete(:fq) unless @params[:fq].blank?
          super
        end

        ##
        # Removes params unsupported by the API
        #
        # @param [Hash] unfiltered_params Unfiltered params
        # @return [Hash] Filtered params
        # @todo implement in the API / map to s'thing else / raise error if
        #   present
        def delete_unsupported_params
          super
          ['spellcheck.q', 'facet.query', 'facet.pivot', :sort].each do |k|
            @params.delete(k)
          end
        end
      end
    end
  end
end
