module RSolr
  module Europeana
    ##
    # Container module for response rewriters
    module ResponseRewriter
      autoload :Base, 'rsolr/europeana/response_rewriter/base'
      autoload :Record, 'rsolr/europeana/response_rewriter/record'
      autoload :Search, 'rsolr/europeana/response_rewriter/search'
    end
  end
end
