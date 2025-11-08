# frozen_string_literal: true

module Sales
  module Subagents
    DATA = {
      "KJS" => {
        "BEHAR/RODIER" => { name: "ARQUI", pct: 0.0010 },
        "BEHAR/PUNTO"  => { name: "ARQUI", pct: 0.0010 },
        "BEHZA"        => { name: "ARQUI", pct: 0.0010 },
        "DAN/CARLOS SANDOVAL" => { name: "CHOCHO", pct: 0.0050 },
        "BERAL"        => { name: "DAN",   pct: 0.0200 },
        "BENNY SHWARTZ" => { name: "CHOCHO", pct: 0.0175 },
        "KURI"         => { name: "ARQUI", pct: 0.0200 },
        "BORIS"        => { name: "CHOCHO", pct: 0.0050 }
      },
      "BONANZA" => {
        "BEHAR/RODIER" => { name: "ARQUI",  pct: 0.0005 },
        "BEHAR/PUNTO"  => { name: "ARQUI",  pct: 0.0005 },
        "BEHZA"        => { name: "ARQUI",  pct: 0.0005 },
        "DAN/CARLOS SANDOVAL" => { name: "CHOCHO", pct: 0.0050 },
        "BERAL"        => { name: "DAN",    pct: 0.0200 },
        "BENNY SHWARTZ" => { name: "CHOCHO", pct: 0.0100 },
        "KURI"         => { name: "ARQUI",  pct: 0.0200 },
        "BORIS"        => { name: "CHOCHO", pct: 0.0050 }
      }
    }.freeze

    def self.entries_for(supplier_code, customer_name)
      cfg = DATA.dig(supplier_code, customer_name)
      return [] unless cfg
      cfg.is_a?(Array) ? cfg : [ cfg ]
    end

    def self.display_name_for(supplier_code, customer_name, pct)
      entries_for(supplier_code, customer_name).find do |entry|
        (entry[:pct].to_f - pct.to_f).abs < 1e-6
      end&.fetch(:name, nil)
    end
  end
end
