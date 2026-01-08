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
    # Ahora se incluyen los movimientos de ventas y transfers sin venta para un desglose completo.
    def render
      Prawn::Document.new(page_size: "A4") do |pdf|
        build_header(pdf)
        pdf.move_down 12
        build_summary(pdf)
        pdf.move_down 16
        build_sales_table(pdf)
        pdf.move_down 12
        build_transfers_table(pdf)
      end.render
    end

    private

    def build_header(pdf)
      pdf.text "Customer Closing", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Cliente: #{customer_name}"
      pdf.text "Grupo: #{customer_group_name}"
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

    def customer_group_name
      customer = @customer_closing&.customer
      return "Sin grupo" unless customer
      group = CustomerGroups.build(Customer.all).find do |g|
        g[:customers].any? { |c| c.id == customer.id }
      end
      group ? group[:name] : "Sin grupo"
    end

    def safe_totals
      @customer_closing&.totals || {}
    end

    def build_summary(pdf)
      totals = safe_totals
      transfers = decimal_value(totals[:transferencias])
      transfers_recibidas = decimal_value(totals[:transferencias_recibidas])
      total_cliente = total_cliente_value(totals)

      pdf.table(
        [
          [ "SPEI aplicados", currency(transfers) ],
          [ "Transfers recibidos (sin venta)", currency(transfers_recibidas) ],
          [ "Total cliente", currency(total_cliente) ]
        ],
        width: pdf.bounds.width
      ) do
        cells.padding = 8
        cells.borders = [ :bottom ]
        column(0).font_style = :bold
      end
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

    def build_sales_table(pdf)
      sales = @customer_closing.sales_for_closing
      pdf.text "Movimientos de ventas", style: :bold
      if sales.empty?
        pdf.move_down 6
        pdf.text "Sin ventas en este cierre."
        return
      end

      rows = sales.map do |sale|
        [
          sale.code,
          format_date(sale.date),
          currency(sale.total_transfer_applied),
          currency(sale.customer_balance)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Código", "Fecha", "SPEI", "Saldo cliente" ] ] + rows,
        width: pdf.bounds.width,
        header: true
      ) do
        row(0).font_style = :bold
        cells.padding = 6
        self.row_colors = [ "F8FAFC", "FFFFFF" ]
      end
    end

    def build_transfers_table(pdf)
      transfers = @customer_closing.transfers_without_sale_for_closing
      pdf.text "Transfers recibidos (sin venta)", style: :bold
      if transfers.empty?
        pdf.move_down 6
        pdf.text "Sin transfers registrados."
        return
      end

      rows = transfers.map do |t|
        [
          t.code,
          format_date(t.occurred_at),
          t.entity_label(:from),
          currency(t.amount)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Código", "Fecha", "Origen", "Monto" ] ] + rows,
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
      I18n.l(date.to_date)
    rescue
      date.to_s
    end
  end
end
