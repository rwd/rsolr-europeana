module RSolr
  module Europeana
    ##
    # Europeana REST API client with RSolr interface
    class Client < RSolr::Client
      def initialize(connection, options = {})
        options[:url] = 'http://www.europeana.eu/api/v2'
        super(connection, options)
      end

      def execute(request_context)
        RSolr::Europeana.logger.debug(
          "Europeana API request URL: #{request_context[:uri]}"
        )
        super
      end

      def build_request(path, opts)
        path, opts = adapt_request_for_api(path, opts)
        self.class.default_wt = 'json'
        super(path, opts)
      end

      def adapt_response(request, response)
        result = super
        if result[:object]
          rewriter = ResponseRewriter::Record.new(result)
        else
          rewriter = ResponseRewriter::Search.new(result)
        end
        rewriter.response
      end

      protected

      def adapt_request_for_api(_path, opts)
        if (opts[:params][:qt] == 'document') && opts[:params][:id]
          rewriter = RequestRewriter::Record.new(opts[:params])
        else
          rewriter = RequestRewriter::Search.new(opts[:params])
        end
        rewritten_params = rewriter.params.merge(wskey: @options[:api_key])
        [rewriter.path, opts.merge(params: rewritten_params)]
      end
    end
  end
end
