require "prawn"
require "prawn/table"
require "active_support/number_helper"
require "bigdecimal"

module CustomerClosings
  class PdfReport
    include ActiveSupport::NumberHelper

    def initialize(customer_closing)
      @customer_closing = customer_closing
    end

    # Total depositado: calculado vía CustomerClosing#totals[:total_depositado] (no existe columna directa).
    # Total cliente: preferimos la columna customer_balance para reflejar el saldo guardado en el cierre;
    # si está nil, usamos CustomerClosing#totals[:total_cliente].
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
      pdf.text "Customer Closing", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Cliente: #{customer_name}"
      pdf.text "Fecha del closing: #{closing_date}"
    end

    def customer_name
      customer = @customer_closing&.customer
      return "Cliente no asignado" unless customer

      [ customer.code, customer.name ].compact.join(" - ")
    end

    def closing_date
      @customer_closing&.closing&.business_date || "-"
    end

    def safe_totals
      @customer_closing&.totals || {}
    end

    def summary_rows
      totals = safe_totals
      total_depositado = decimal_value(totals[:total_depositado])
      total_cliente = total_cliente_value(totals)
      [
        [ "Total depositado", currency(total_depositado) ],
        [ "Total cliente", currency(total_cliente) ]
      ]
    end

    def decimal_value(value)
      BigDecimal(value.to_s.presence || "0")
    end

    def total_cliente_value(totals)
      value = @customer_closing&.customer_balance
      value = totals[:total_cliente] if value.nil?
      decimal_value(value)
    end

    def currency(value)
      number_to_currency(value, unit: "$")
    end
  end
end
