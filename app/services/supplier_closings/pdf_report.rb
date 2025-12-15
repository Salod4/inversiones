require "prawn"
require "prawn/table"
require "bigdecimal"
require "active_support/number_helper"

module SupplierClosings
  class PdfReport
    include ActiveSupport::NumberHelper

    def self.render(supplier_closing)
      new(supplier_closing).render
    end

    def initialize(supplier_closing)
      @supplier_closing = supplier_closing
    end

    # Renders a PDF for a single SupplierClosing with the key monetary figures.
    # Total asignado = amount_owed_to_supplier column.
    # Retcomp = supplier_credit column (credit/retenciones al proveedor).
    # Saldo pendiente = mismo valor mostrado en la vista (SupplierClosing#totals[:saldo_pendiente]).
    def render
      Prawn::Document.new(page_size: "A4") do |pdf|
        build_header(pdf)
        pdf.move_down 14
        pdf.table(summary_rows, width: pdf.bounds.width) do
          cells.padding = 8
          cells.borders = [ :bottom ]
          column(0).font_style = :bold
        end
      end.render
    end

    private

    def build_header(pdf)
      pdf.text "Supplier Closing", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Proveedor: #{supplier_name}"
      pdf.text "Fecha del closing: #{closing_date}"
    end

    def summary_rows
      total_asignado = decimal_value(@supplier_closing&.amount_owed_to_supplier)
      retcomp = decimal_value(@supplier_closing&.supplier_credit)
      # Saldo pendiente debe reflejar el mismo valor mostrado en la vista:
      # ret_comp_total - transferido (calculado en SupplierClosing#totals).
      pending_balance = decimal_value(@supplier_closing&.totals&.fetch(:saldo_pendiente, 0))

      [
        [ "Total asignado", currency(total_asignado) ],
        [ "Retcomp", currency(retcomp) ],
        [ "Saldo pendiente", currency(pending_balance) ]
      ]
    end

    def currency(value)
      number_to_currency(value, unit: "$")
    end

    def decimal_value(value)
      BigDecimal(value.to_s.presence || "0")
    end

    def supplier_name
      supplier = @supplier_closing&.supplier
      return "Proveedor no asignado" unless supplier

      [ supplier.name, supplier.code.presence ].compact.join(" ")
    end

    def closing_date
      @supplier_closing&.closing&.business_date || "-"
    end
  end
end
