module Spree
  module Admin
    module Orders
      module CustomerDetailsControllerDecorator
        def update
          params[:order][:user_id] = nil if guest_checkout?
          if @order.update(order_params)
            @order.update_with_updater! # Causes Avatax to recalculate tax and totals
            @order.associate_user!(@user, @order.email.blank?) unless guest_checkout?
            @order.next if @order.address?
            @order.refresh_shipment_rates(Spree::ShippingMethod::DISPLAY_ON_BACK_END)

            if @order.errors.empty?
              flash[:success] = Spree.t('customer_details_updated')
              redirect_to spree.edit_admin_order_url(@order)
            else
              render action: :edit
            end
          else
            render action: :edit
          end
        end
      end
    end
  end
end

::Spree::Admin::Orders::CustomerDetailsController.prepend(Spree::Admin::Orders::CustomerDetailsControllerDecorator)