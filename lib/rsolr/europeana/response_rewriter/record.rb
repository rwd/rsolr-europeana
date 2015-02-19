module RSolr
  module Europeana
    module ResponseRewriter
      ##
      # Record response rewriter
      class Record < Base
        ##
        # Adapts a response from the API's Record method to resemble a Solr
        # query response of one document.
        #
        # @param [Hash] response The Europeana REST API response
        # @return [Hash]
        def rewrite_response
          @response = {
            'response' => {
              'numFound' => 1,
              'start' => 0,
              'docs' => [solr_doc_from_europeana_object]
            }
          }
        end

        def europeana_object
          @europeana_response[:object]
        end

        def edm_root_fields
          europeana_object.select do |key, _value|
            [:edmDatasetName, :language, :type, :title, :about,
             :europeanaCollectionName, :timestamp_created_epoch,
             :timestamp_update_epoch, :timestamp_created, :timestamp_update
            ].include?(key)
          end
        end

        def edm_proxy
          europeana_object[:proxies].first.reject do |key, _value|
            [:proxyFor, :europeanaProxy, :proxyIn, :about].include?(key)
          end
        end

        def edm_aggregation
          europeana_object[:aggregations].first.reject do |key, _value|
            [:webResources, :aggregatedCHO, :about].include?(key)
          end
        end

        def edm_europeana_aggregation
          europeana_object[:europeanaAggregation].reject do |key, _value|
            [:about, :aggregatedCHO].include?(key)
          end
        end

        def solr_doc_from_europeana_object
          doc = edm_root_fields
          doc[:id] = europeana_object[:about]
          doc.merge!(edm_proxy)
          doc.merge!(edm_aggregation)
          doc.merge!(edm_europeana_aggregation)
          flatten_edm_doc(doc)
        end

        def flatten_edm_doc(doc)
          doc.dup.each_pair do |key, value|
            if value.is_a?(Array)
              doc[key] = value.uniq
            elsif value.is_a?(Hash)
              doc.merge!(flatten_lang_labels(key, value)) if value.key?(:def)
              doc.delete(key)
            end
          end
          doc
        end

        def flatten_lang_labels(field, lang_labels)
          lang_labels.each_with_object({}) do |(lang, labels), flat_hash|
            flat_hash["#{field}_#{lang}"] = labels
          end
        end
      end
    end
  end
end
