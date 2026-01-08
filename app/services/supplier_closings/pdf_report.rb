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
    # Incluye desglose de salidas (transfers sin venta) con movimiento, fecha y monto.
    def render
      Prawn::Document.new(page_size: "A4") do |pdf|
        build_header(pdf)
        pdf.move_down 14
        build_summary(pdf)
        pdf.move_down 14
        build_transfers(pdf)
        pdf.move_down 14
        build_sales(pdf)
      end.render
    end

    private

    def build_header(pdf)
      pdf.text "Supplier Closing", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Proveedor: #{supplier_name}"
      pdf.text "Fecha del closing: #{closing_date}"
    end

    def build_summary(pdf)
      total_asignado = decimal_value(@supplier_closing&.amount_owed_to_supplier)
      retcomp = decimal_value(@supplier_closing&.supplier_credit)
      # Saldo pendiente debe reflejar el mismo valor mostrado en la vista:
      # ret_comp_total - transferido (calculado en SupplierClosing#totals).
      pending_balance = decimal_value(@supplier_closing&.totals&.fetch(:saldo_pendiente, 0))

      pdf.table(
        [
          [ "Total asignado", currency(total_asignado) ],
          [ "Retcomp", currency(retcomp) ],
          [ "Saldo pendiente", currency(pending_balance) ]
        ],
        width: pdf.bounds.width
      ) do
        cells.padding = 8
        cells.borders = [ :bottom ]
        column(0).font_style = :bold
      end
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

    def build_transfers(pdf)
      transfers = @supplier_closing.transfers_without_sale_for_closing
      pdf.text "Desglose de salidas", style: :bold
      if transfers.empty?
        pdf.move_down 6
        pdf.text "Sin movimientos."
        return
      end

      rows = transfers.map do |t|
        [
          movement_label(t),
          format_date(t.occurred_at),
          currency(t.amount)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Movimiento", "Fecha", "Cantidad" ] ] + rows,
        width: pdf.bounds.width,
        header: true
      ) do
        row(0).font_style = :bold
        cells.padding = 6
        self.row_colors = [ "F8FAFC", "FFFFFF" ]
      end
    end

    def movement_label(transfer)
      from = transfer.entity_label(:from)
      to = transfer.entity_label(:to)
      parts = [ from.presence, to.presence ].compact
      return parts.first if parts.size <= 1
      "#{parts[0]} a #{parts[1]}"
    end

    def build_sales(pdf)
      sales = @supplier_closing.sales_for_closing
      pdf.text "Ventas asignadas al proveedor", style: :bold
      if sales.empty?
        pdf.move_down 6
        pdf.text "Sin ventas en este cierre."
        return
      end

      rows = sales.map do |s|
        [
          s.code,
          format_date(s.date),
          currency(s.gross_deposit.to_d - s.provider_commission.to_d)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Movimiento", "Fecha", "Retorno completo" ] ] + rows,
        width: pdf.bounds.width,
        header: true
      ) do
        row(0).font_style = :bold
        cells.padding = 6
        self.row_colors = [ "F8FAFC", "FFFFFF" ]
      end
    end

    def format_date(date)
      return "-" unless date
      I18n.l(date)
    rescue
      date.to_s
    end
  end
end
