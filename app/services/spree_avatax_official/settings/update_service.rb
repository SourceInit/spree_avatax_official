module SpreeAvataxOfficial
  module Settings
    class UpdateService < SpreeAvataxOfficial::Base
      def call(params:)
        update_settings(params)
      end

      private

      def update_settings(params)
        update_address_settings(params[:ship_from])

        SpreeAvataxOfficial::Config.account_number             = params[:account_number] if params.key?(:account_number)
        SpreeAvataxOfficial::Config.license_key                = params[:license_key] if params.key?(:license_key)
        SpreeAvataxOfficial::Config.company_code               = params[:company_code] if params.key?(:company_code)
        SpreeAvataxOfficial::Config.endpoint                   = params[:endpoint] if params.key?(:endpoint)
        SpreeAvataxOfficial::Config.address_validation_enabled = params[:address_validation_enabled] if params.key?(:address_validation_enabled)
        SpreeAvataxOfficial::Config.commit_transaction_enabled = params[:commit_transaction_enabled] if params.key?(:commit_transaction_enabled)
        SpreeAvataxOfficial::Config.enabled                    = params[:enabled] if params.key?(:enabled)
        SpreeAvataxOfficial::Config.enforce_strict_rates       = params[:enforce_strict_rates] if params.key?(:enforce_strict_rates)

        remove_tax_rates!(params[:enabled]) if SpreeAvataxOfficial::Config.enforce_strict_rates
      end

      def update_address_settings(ship_from_params)
        return unless ship_from_params

        SpreeAvataxOfficial::Config.ship_from_address = {
            line1:      ship_from_params[:line1],
            line2:      ship_from_params[:line2],
            city:       ship_from_params[:city],
            region:     ship_from_params[:region],
            country:    ship_from_params[:country],
            postalCode: ship_from_params[:postal_code]
        }
      end

      # This could hinge off of a new config option like 'enforce_strict_rates' or similar,
      # that way it could be opted out of if desired.
      def remove_tax_rates!(enabled_params)
        if SpreeAvataxOfficial::Config.enabled
          Rails.logger.debug "Remove non-Avatax"
          ::Spree::TaxRate.all.joins(:calculator)
          .where.not(calculator: {type: "SpreeAvataxOfficial::Calculator::AvataxTransactionCalculator"})
          .destroy_all
        else
          Rails.logger.debug "Remove Avatax"
          # If Avatax will be disabled, we don't want its rates left lying about.
          # They will get picked up along with Spree native rates and do bad things
          # to tax calulations:
          # If Spree rate creates an adjustment for $1.00,
          # each of the Avatax rates for the zone/category will also create a $1.00
          # adjustment. After the adjustment is created, the recalculation callback
          # will run. Spree adjustment will remain as $1.00, while Avatax ones
          # will look at the tax adjustments and sum them for the new amount.
          # This means the Avatax one will become $2.00. The next time the amount
          # is recalculated it grow again. On and on and on until we exceed the column
          # range in the database.
          ::Spree::TaxRate.all.joins(:calculator)
          .where(calculator: {type: "SpreeAvataxOfficial::Calculator::AvataxTransactionCalculator"})
          .destroy_all
        end
      end
    end
  end
end
