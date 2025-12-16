require "prawn"
require "prawn/table"
require "active_support/number_helper"
require "bigdecimal"

module CustomerGroups
  class PdfReport
    include ActiveSupport::NumberHelper

    class GroupNotFound < StandardError; end

    def initialize(closing:, group_name:)
      @closing = closing
      @group_name = group_name
    end

    # Total depositado (grupo): suma de CustomerClosing#totals[:total_depositado] para los miembros.
    # Total a regresar: suma de customer_balance (saldo guardado en el cierre) o, si falta, totals[:total_cliente].
    def render
      group = group_definition
      raise GroupNotFound unless group

      closings_in_group = customer_closings_in_group(group)
      opening_balance = OpeningBalance.total_for_group(@group_name)

      if closings_in_group.empty? && opening_balance.zero?
        raise GroupNotFound
      end

      totals = aggregate_totals(closings_in_group, opening_balance)

      Prawn::Document.new(page_size: "A4") do |pdf|
        pdf.text "Customer Group Closing", size: 18, style: :bold
        pdf.move_down 6
        pdf.text "Grupo: #{group_title}"
        pdf.text "Fecha del closing: #{closing_date}"
        pdf.move_down 14
        pdf.table(summary_rows(totals), width: pdf.bounds.width) do
          cells.padding = 8
          cells.borders = [ :bottom ]
          column(0).font_style = :bold
        end
      end.render
    end

    private

    def group_definition
      ::CustomerGroups.find_by_name(@group_name, Customer.all)
    end

    def customer_closings_in_group(group)
      return [] unless @closing && group

      ids = group[:customers].map(&:id)
      @closing.customer_closings.includes(:customer).select { |cc| ids.include?(cc.customer_id) }
    end

    def aggregate_totals(customer_closings, opening_balance = 0)
      totals = customer_closings.each_with_object({ total_depositado: BigDecimal("0"), total_cliente: BigDecimal("0") }) do |cc, acc|
        cc_totals = cc&.totals || {}
        acc[:total_depositado] += decimal_value(cc_totals[:total_depositado])

        total_cliente = cc&.customer_balance
        total_cliente = cc_totals[:total_cliente] if total_cliente.nil?
        acc[:total_cliente] += decimal_value(total_cliente)
      end
      totals[:total_cliente] += decimal_value(opening_balance)
      totals
    end

    def group_title
      @group_name.presence || "Grupo sin nombre"
    end

    def closing_date
      @closing&.business_date || "-"
    end

    def currency(value)
      number_to_currency(value, unit: "$")
    end

    def decimal_value(value)
      BigDecimal(value.to_s.presence || "0")
    end

    def summary_rows(totals)
      [
        [ "Total depositado (grupo)", currency(totals[:total_depositado]) ],
        [ "Total a regresar", currency(totals[:total_cliente]) ]
      ]
    end
  end
end
