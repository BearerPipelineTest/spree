module Spree
  module Api
    module Webhooks
      module StockMovementDecorator
        def self.prepended(base)
          base.around_save :queue_webhooks_requests_for_variant_out_of_stock!
          base.around_save :queue_webhooks_requests_for_variant_back_in_stock!
          base.around_save :queue_webhooks_requests_for_product_back_in_stock!
        end

        private

        delegate :variant, to: :stock_item
        delegate :product, to: :variant

        def queue_webhooks_requests_for_variant_out_of_stock!
          variant_in_stock_before_update = variant.full_in_stock?
          yield
          if variant_in_stock_before_update && !variant.full_in_stock?
            reload
            stock_item.variant.queue_webhooks_requests!('variant.out_of_stock')
          end
        end

        def queue_webhooks_requests_for_variant_back_in_stock!
          variant_was_out_of_stock = !variant.full_in_stock?
          yield
          if variant_was_out_of_stock && variant.full_in_stock?
            reload
            variant.queue_webhooks_requests!('variant.back_in_stock')
          end
        end

        def queue_webhooks_requests_for_product_back_in_stock!
          product_was_out_of_stock = !product.full_in_stock?
          yield
          if product_was_out_of_stock && product.full_in_stock?
            product.queue_webhooks_requests!('product.back_in_stock')
          end
        end
      end
    end
  end
end

Spree::StockMovement.prepend(Spree::Api::Webhooks::StockMovementDecorator)
