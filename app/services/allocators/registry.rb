# app/services/allocators/registry.rb
module Allocators
  class Registry
    MAP = {
      'domain_pair' => 'Allocators::DomainPair',
      'nameservers' => 'Allocators::Nameservers',
      'domain_transfer_seed' => 'Allocators::DomainTransferSeed'
      # add more like "mailbox" => "Allocators::Mailbox"
    }.freeze

    def self.run!(name:, config:, attempt:)
      klass_name = MAP.fetch(name) { raise "Unknown allocator: #{name}" }
      klass = klass_name.constantize
      klass.new(config: config, attempt: attempt).call
    end
  end
end
