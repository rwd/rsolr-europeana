require 'rsolr'
require 'rsolr/europeana/version'
require 'logger'

module RSolr
  ##
  # Connects an RSolr consumer to the Europeana REST API
  module Europeana
    autoload :Client, 'rsolr/europeana/client'
    autoload :RequestRewriter, 'rsolr/europeana/request_rewriter'
    autoload :ResponseRewriter, 'rsolr/europeana/response_rewriter'

    # Base URL of the Europeana REST API
    URL = 'http://www.europeana.eu/api/v2'

    # @return [RSolr::Europeana::Client]
    def self.connect(*args)
      driver = args[0].is_a?(Class) ? args[0] : RSolr::Connection
      opts = args[-1].is_a?(Hash) ? args[-1] : {}
      RSolr::Europeana::Client.new driver.new, opts
    end

    ##
    # Logger for the RSolr::Europeana library
    #
    # Uses the Rails logger if available, otherwise STDOUT
    #
    # @return [ActiveSupport::Logger,Logger]
    def self.logger
      return @logger if @logger
      if defined?(Rails) && Rails.logger
        @logger = Rails.logger
      else
        @logger = Logger.new(STDOUT)
      end
      @logger
    end
  end
end
