require "prawn"
require "prawn/table"
require "active_support/number_helper"
require "bigdecimal"

module CustomerClosings
  class WeeklyPdfReport
    include ActiveSupport::NumberHelper

    def initialize(customer_closing, start_date:, end_date:)
      @customer_closing = customer_closing
      @start_date = start_date
      @end_date = end_date
    end

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
      pdf.text "Customer Closing (Semanal)", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Cliente: #{customer_name}"
      pdf.text "Periodo: #{format_date(@start_date)} - #{format_date(@end_date)}"
    end

    def customer_name
      customer = @customer_closing&.customer
      return "Cliente no asignado" unless customer

      [ customer.code, customer.name ].compact.join(" - ")
    end

    def range
      @range ||= @start_date.beginning_of_day..@end_date.end_of_day
    end

    def sales
      @sales ||= Sale.where(customer_id: @customer_closing.customer_id, date: @start_date..@end_date)
                     .includes(:transfers)
                     .order(:date, :code)
    end

    def sales_ids
      @sales_ids ||= sales.pluck(:id)
    end

    def transfers_in_range
      @transfers_in_range ||= if sales_ids.empty?
        []
      else
        Transfer.where(sale_id: sales_ids, occurred_at: range).to_a
      end
    end

    def transfers_without_sale
      Transfer.where(sale_id: nil)
              .where(to_entity_type: "Customer", to_entity_id: @customer_closing.customer_id)
              .where.not(from_entity_type: "Customer")
              .where(occurred_at: range)
              .order(:occurred_at, :code)
    end

    def outgoing_sum(transfers)
      transfers.reduce(0.to_d) { |sum, t| sum + t.total_outgoing }
    end

    def transfer_notes_by_sale_id
      @transfer_notes_by_sale_id ||= begin
        notes = Hash.new { |h, k| h[k] = [] }
        transfers_in_range.each do |t|
          note = t.note.to_s.strip
          notes[t.sale_id] << note if note.present?
        end
        notes
      end
    end

    def transfer_notes_for_sale(sale)
      notes = transfer_notes_by_sale_id[sale.id] || []
      notes.any? ? notes.join(" | ") : "—"
    end

    def transfers_applied_total
      outgoing_sum(transfers_in_range)
    end

    def transfers_received_total
      direct_transfers_summary[:incoming_from_others]
    end

    def total_cliente
      direct_transfers = direct_transfers_summary
      gross_total = sales.sum(:gross_deposit)
      provider_commission_total = sales.sum(:provider_commission)
      seller_commission_total = SalesUser.where(sale_id: sales_ids).sum(:commission_amount)
      total_after_pcts = gross_total - provider_commission_total - seller_commission_total
      total_after_pcts - transfers_applied_total - transfers_received_total -
        direct_transfers[:outgoing] + direct_transfers[:incoming_from_customers]
    end

    def direct_transfers_summary
      @direct_transfers_summary ||= {
        outgoing: Transfer.customer_outgoing_total(@customer_closing.customer_id, range: range),
        incoming_from_customers: Transfer.customer_incoming_from_customers_total(@customer_closing.customer_id, range: range),
        incoming_from_others: Transfer.customer_incoming_from_others_total(@customer_closing.customer_id, range: range)
      }
    end

    def build_summary(pdf)
      pdf.table(
        [
          [ "SPEI aplicados", currency(transfers_applied_total) ],
          [ "Transfers recibidos (sin venta)", currency(transfers_received_total) ],
          [ "Total cliente", currency(total_cliente) ]
        ],
        width: pdf.bounds.width
      ) do
        cells.padding = 8
        cells.borders = [ :bottom ]
        column(0).font_style = :bold
      end
    end

    def build_sales_table(pdf)
      pdf.text "Movimientos de ventas", style: :bold
      if sales.empty?
        pdf.move_down 6
        pdf.text "Sin ventas en este periodo."
        return
      end

      sale_transfer_totals = Hash.new(0.to_d)
      transfers_in_range.each do |t|
        sale_transfer_totals[t.sale_id] += t.total_outgoing
      end

      rows = sales.map do |sale|
        [
          sale.code,
          format_date(sale.date),
          transfer_notes_for_sale(sale),
          currency(sale_transfer_totals[sale.id]),
          currency(sale.customer_balance)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Código", "Fecha", "Notas transfer", "SPEI", "Saldo cliente" ] ] + rows,
        width: pdf.bounds.width,
        header: true
      ) do
        row(0).font_style = :bold
        cells.padding = 6
        self.row_colors = [ "F8FAFC", "FFFFFF" ]
      end
    end

    def build_transfers_table(pdf)
      transfers = transfers_without_sale
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
          t.note.to_s,
          currency(t.total_outgoing)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Código", "Fecha", "Nota", "Monto" ] ] + rows,
        width: pdf.bounds.width,
        header: true
      ) do
        row(0).font_style = :bold
        cells.padding = 6
        self.row_colors = [ "F8FAFC", "FFFFFF" ]
      end
    end

    def currency(value)
      number_to_currency(value, unit: "$")
    end

    def format_date(date)
      return "-" unless date
      I18n.l(date.to_date)
    rescue
      date.to_s
    end
  end
end
