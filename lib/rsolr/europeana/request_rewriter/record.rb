module RSolr
  module Europeana
    module RequestRewriter
      ##
      # Record request rewriter
      class Record < Base
        @rewrite_methods = [:delete_record_params, :delete_params,
                            :rewrite_solr_local_params]

        ##
        # Europeana Record ID
        attr_reader :id

        def initialize(solr_params)
          super
          @id = solr_params[:id]
        end

        #
        # URL path to the requested record
        def path
          "/api/v2/record/#{@id}.json"
        end

        protected

        def delete_record_params
          @params.delete(:id)
        end
      end
    end
  end
end
