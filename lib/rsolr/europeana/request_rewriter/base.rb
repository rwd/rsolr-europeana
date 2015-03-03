module RSolr
  module Europeana
    module RequestRewriter
      ##
      # Abstract base class for request rewriters
      class Base
        class << self
          ##
          # @!attribute rewrite_methods
          #   @return [Array] methods to call when rewriting with {#execute}
          attr_accessor :rewrite_methods
        end
        @rewrite_methods = [:delete_params, :rewrite_solr_local_params]

        def initialize(solr_params)
          @solr_params = HashWithIndifferentAccess.new(solr_params)
        end

        ##
        # Return the API URL path for the requested query
        #
        # Sub-classes need to implement this for the type of query represented.
        #
        # @raise [NotImplementedError] if called on this class directly
        def path
          fail NotImplementedError
        end

        def execute
          return @params unless @params.nil?
          @params = @solr_params
          self.class.rewrite_methods.each { |meth| send(meth) }
          @params
        end

        protected

        def delete_params
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
            fail ArgumentError, "Unexpected param type for \"#{name}\": #{value.class}"
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
