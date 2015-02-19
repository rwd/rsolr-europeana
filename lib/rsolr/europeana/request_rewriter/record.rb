module RSolr
  module Europeana
    module RequestRewriter
      ##
      # Record request rewriter
      class Record < Base
        def initialize(solr_params)
          super
          @id = solr_params[:id]
        end

        def rewrite_params
          @params.delete(:id)
          super
        end

        def path
          "/api/v2/record/#{@id}.json"
        end
      end
    end
  end
end
