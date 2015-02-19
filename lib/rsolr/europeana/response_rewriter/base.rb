module RSolr
  module Europeana
    module ResponseRewriter
      ##
      # Base class for response rewriters
      class Base
        def initialize(europeana_response)
          @europeana_response = europeana_response
        end

        def response
          rewrite_response if @response.nil?
          @response
        end

        def rewrite_response
          fail NotImplementedError
        end
      end
    end
  end
end
