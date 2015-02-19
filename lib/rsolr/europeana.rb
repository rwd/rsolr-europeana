require 'rsolr/europeana/version'

module RSolr
  ##
  # Helps an RSolr consumer be connected to the Europeana REST API
  module Europeana
    autoload :Client, 'rsolr/europeana/client'
    autoload :RequestRewriter, 'rsolr/europeana/request_rewriter'
    autoload :ResponseRewriter, 'rsolr/europeana/response_rewriter'

    def self.connect(*args)
      driver = args[0].is_a?(Class) ? args[0] : RSolr::Connection
      opts = args[-1].is_a?(Hash) ? args[-1] : {}
      RSolr::Europeana::Client.new driver.new, opts
    end

    def self.logger
      unless @logger
        if defined?(Rails) && Rails.logger
          @logger = Rails.logger
        else
          @logger = Logger.new(STDOUT)
        end
      end
      @logger
    end
  end
end
