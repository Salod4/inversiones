# frozen_string_literal: true

module CustomerGroups
  GROUPS = {
    "ARQUI" => { prefix: "ARQUI", except: [ "ARQUI KAR" ] },
    "NADJAR" => { prefix: "NADJAR" },
    "BEHAR" => { prefix: "BEHAR" },
    "DUMA" => { prefix: "DUMA" }
  }.freeze

  def self.names
    GROUPS.keys
  end

  def self.build(scope = Customer.all)
    customer_table = Customer.arel_table
    GROUPS.map do |name, cfg|
      rel = scope.where(customer_table[:name].matches("#{cfg[:prefix]}%"))
      rel = rel.where.not(customer_table[:name].in(cfg[:except])) if cfg[:except].present?
      customers = rel.order(:name).to_a
      next if customers.empty?

      {
        name: name,
        customers: customers,
        count: customers.size
      }
    end.compact
  end

  def self.find_by_name(name, scope = Customer.all)
    return nil if name.blank?
    build(scope).find { |group| group[:name].casecmp?(name.to_s) }
  end
end
