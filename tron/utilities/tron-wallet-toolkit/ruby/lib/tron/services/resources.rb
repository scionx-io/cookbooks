# lib/tron/services/resources.rb
require_relative '../utils/http'
require_relative '../utils/address'

module Tron
  module Services
    class Resources
      def initialize(config)
        @config = config
      end

      def get(address)
        validate_address!(address)
        
        # Try getaccountresource first
        begin
          get_account_resources(address)
        rescue
          # Fallback to getaccount if getaccountresource fails
          get_account_resources_fallback(address)
        end
      end

      private

      def get_account_resources(address)
        url = "#{@config.base_url}/wallet/getaccountresource"
        headers = api_headers
        
        response = Utils::HTTP.post(url, { address: address, visible: true }.to_json, headers)
        
        # Validate response structure
        unless response.is_a?(Hash)
          raise "Unexpected API response format for account resources"
        end
        
        # Handle error response format
        if response.key?('Error')
          return default_resources
        end

        # Validate required fields exist
        ['freeNetLimit', 'freeNetUsed', 'TotalNetLimit', 'EnergyLimit', 'EnergyUsed'].each do |field|
          unless response.key?(field)
            puts "Warning: Missing field '#{field}' in account resources response: #{response}" if $DEBUG
          end
        end

        free_net_limit = response['freeNetLimit']&.to_i || 0
        free_net_used = response['freeNetUsed']&.to_i || 0
        total_net_limit = response['TotalNetLimit']&.to_i || 0
        energy_limit = response['EnergyLimit']&.to_i || 0
        energy_used = response['EnergyUsed']&.to_i || 0
        
        available_bandwidth = [0, free_net_limit - free_net_used].max
        available_energy = [0, energy_limit - energy_used].max
        available_total_net = [0, total_net_limit].max

        {
          bandwidth: available_bandwidth,
          bandwidthLimit: free_net_limit,
          energy: available_energy,
          energyLimit: energy_limit,
          storage: 0,
          storageLimit: 0,
          totalFreeBandwidth: available_total_net,
          totalFreeBandwidthLimit: total_net_limit
        }
      end

      def get_account_resources_fallback(address)
        url = "#{@config.base_url}/wallet/getaccount"
        headers = api_headers
        
        response = Utils::HTTP.post(url, { address: address, visible: true }.to_json, headers)
        
        # Validate response structure
        unless response.is_a?(Hash) && response.key?('data')
          raise "Unexpected response format from getaccount endpoint"
        end
        
        account_data = response['data']&.first || {}
        
        free_net_limit = account_data['freeNetLimit']&.to_i || 0
        free_net_used = account_data['freeNetUsed']&.to_i || 0
        energy_limit = account_data['EnergyLimit']&.to_i || 0
        energy_used = account_data['EnergyUsed']&.to_i || 0
        storage_limit = account_data['StorageLimit']&.to_i || 0
        storage_used = account_data['StorageUsed']&.to_i || 0
        
        {
          bandwidth: [0, free_net_limit - free_net_used].max,
          bandwidthLimit: free_net_limit,
          energy: [0, energy_limit - energy_used].max,
          energyLimit: energy_limit,
          storage: [0, storage_limit - storage_used].max,
          storageLimit: storage_limit,
          totalFreeBandwidth: 0,
          totalFreeBandwidthLimit: 0
        }
      end

      def validate_address!(address)
        raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
      end

      def api_headers
        headers = { 'accept' => 'application/json', 'Content-Type' => 'application/json' }
        headers['TRON-PRO-API-KEY'] = @config.api_key if @config.api_key
        headers
      end

      def default_resources
        {
          bandwidth: 0,
          bandwidthLimit: 0,
          energy: 0,
          energyLimit: 0,
          storage: 0,
          storageLimit: 0,
          totalFreeBandwidth: 0,
          totalFreeBandwidthLimit: 0
        }
      end
    end
  end
end