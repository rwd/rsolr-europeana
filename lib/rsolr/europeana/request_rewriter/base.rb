module RSolr
  module Europeana
    module RequestRewriter
      ##
      # Abstract base class for request rewriters
      class Base
        def initialize(solr_params)
          @solr_params = solr_params
        end

        def path
          fail NotImplementedError
        end

        def params
          if @params.nil?
            @params = @solr_params.dup
            rewrite_params
          end
          @params
        end

        def rewrite_params
          delete_unsupported_params
          rewrite_solr_local_params
        end

        def delete_unsupported_params
          @params.delete(:qt)
          @params.delete(:wt)
        end

        def rewrite_solr_local_params
          @params.each_pair do |name, value|
            @params[name] = rewrite_solr_local_param(name, value)
          end
        end

        def rewrite_solr_local_param(name, value)
          case value
          when NilClass, Fixnum
            value
          when String
            rewrite_solr_local_string(name, value)
          when Array
            value.collect { |one| rewrite_solr_local_param(name, one) }
          else
            fail ArgumentError, "Unexpected param type: #{value.class}"
          end
        end

        def rewrite_solr_local_string(name, value)
          if name == 'query'
            qvalue = value.sub(/\A\{!qf=all_fields\}/, '')
            qvalue.sub(/\A\{.*?=([^ \}]*).*?\}(.*)\Z/, '\1:\2')
          else
            value.sub(/\A\{.*?=([^ \}]*).*?\}(.*)\Z/, '\1:"\2"')
          end
        end
      end
    end
  end
end
