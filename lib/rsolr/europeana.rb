require 'rsolr/europeana/version'

module RSolr
  module Europeana
    autoload :Client, 'rsolr/europeana/client'
    
    def self.connect *args
      driver = Class === args[0] ? args[0] : RSolr::Connection
      opts = Hash === args[-1] ? args[-1] : {}
      RSolr::Europeana::Client.new driver.new, opts
    end
  end
end
