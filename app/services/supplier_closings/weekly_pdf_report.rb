require "prawn"
require "prawn/table"
require "bigdecimal"
require "active_support/number_helper"

module SupplierClosings
  class WeeklyPdfReport
    include ActiveSupport::NumberHelper

    def initialize(supplier_closing, start_date:, end_date:)
      @supplier_closing = supplier_closing
      @start_date = start_date
      @end_date = end_date
    end

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
      pdf.text "Supplier Closing (Semanal)", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Proveedor: #{supplier_name}"
      pdf.text "Periodo: #{format_date(@start_date)} - #{format_date(@end_date)}"
    end

    def supplier_name
      supplier = @supplier_closing&.supplier
      return "Proveedor no asignado" unless supplier

      [ supplier.name, supplier.code.presence ].compact.join(" ")
    end

    def range
      @range ||= @start_date.beginning_of_day..@end_date.end_of_day
    end

    def sales
      @sales ||= Sale.where(supplier_id: @supplier_closing.supplier_id, date: @start_date..@end_date)
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
      Transfer.where(supplier_id: @supplier_closing.supplier_id, sale_id: nil)
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

    def total_asignado
      sales.sum(:gross_deposit)
    end

    def ret_comp_total
      total_asignado - sales.sum(:provider_commission)
    end

    def transferido
      outgoing_sum(Transfer.where(supplier_id: @supplier_closing.supplier_id, occurred_at: range).to_a)
    end

    def saldo_pendiente
      ret_comp_total - transferido
    end

    def build_summary(pdf)
      pdf.table(
        [
          [ "Total asignado", currency(total_asignado) ],
          [ "Retcomp", currency(ret_comp_total) ],
          [ "Saldo pendiente", currency(saldo_pendiente) ]
        ],
        width: pdf.bounds.width
      ) do
        cells.padding = 8
        cells.borders = [ :bottom ]
        column(0).font_style = :bold
      end
    end

    def build_transfers(pdf)
      transfers = transfers_without_sale
      pdf.text "Desglose de salidas", style: :bold
      if transfers.empty?
        pdf.move_down 6
        pdf.text "Sin movimientos."
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
        [ [ "Movimiento", "Fecha", "Nota", "Cantidad" ] ] + rows,
        width: pdf.bounds.width,
        header: true
      ) do
        row(0).font_style = :bold
        cells.padding = 6
        self.row_colors = [ "F8FAFC", "FFFFFF" ]
      end
    end

    def build_sales(pdf)
      pdf.text "Ventas asignadas al proveedor", style: :bold
      if sales.empty?
        pdf.move_down 6
        pdf.text "Sin ventas en este periodo."
        return
      end

      rows = sales.map do |s|
        [
          s.code,
          format_date(s.date),
          transfer_notes_for_sale(s),
          currency(s.gross_deposit.to_d - s.provider_commission.to_d)
        ]
      end

      pdf.move_down 6
      pdf.table(
        [ [ "Movimiento", "Fecha", "Notas transfer", "Retorno completo" ] ] + rows,
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
      I18n.l(date)
    rescue
      date.to_s
    end
  end
end
