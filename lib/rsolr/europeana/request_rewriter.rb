module RSolr
  module Europeana
    ##
    # Container module for request rewriters
    module RequestRewriter
      autoload :Base, 'rsolr/europeana/request_rewriter/base'
      autoload :Record, 'rsolr/europeana/request_rewriter/record'
      autoload :Search, 'rsolr/europeana/request_rewriter/search'
    end
  end
end
