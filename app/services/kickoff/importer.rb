# frozen_string_literal: true

require "csv"
require "roo"

module Kickoff
  class Importer
    class << self
      def import(customers: nil, suppliers: nil, sellers: nil)
        ActiveRecord::Base.transaction do
          import_customers(customers) if customers
          import_suppliers(suppliers) if suppliers
          import_sellers(sellers) if sellers
        end
      end

      private

      def import_customers(io)
        OpeningBalance.customers.delete_all
        OpeningBalance.customer_groups.delete_all

        each_row(io) do |row, source|
          raw_name = row["Cliente"] || row["cliente"]
          amount = parse_amount(row["Total Cliente"] || row["total cliente"] || row["Total"] || row["total"])
          next if raw_name.blank? || amount.zero?

          if raw_name.to_s.strip =~ /\A\s*grupo\s+/i
            group_name = raw_name.to_s.strip.sub(/\A\s*grupo\s+/i, "").strip
            OpeningBalance.create!(
              reference_type: OpeningBalance::TYPES[:customer_group],
              group_name: group_name,
              amount: amount,
              source: source
            )
          else
            customer = find_customer(raw_name)
            OpeningBalance.create!(
              reference_type: OpeningBalance::TYPES[:customer],
              reference_id: customer.id,
              amount: amount,
              source: source
            )
          end
        end
      end

      def import_suppliers(io)
        OpeningBalance.suppliers.delete_all
        missing = []
        imported = 0

        each_row(io) do |row, source|
          raw_name = row["Proveedor"] || row["proveedor"]
          amount = parse_amount(row["Saldo pendiente"] || row["saldo pendiente"] || row["Total"] || row["total"])
          next if raw_name.blank? || amount.zero?

          begin
            supplier = find_supplier(raw_name)
            OpeningBalance.create!(
              reference_type: OpeningBalance::TYPES[:supplier],
              reference_id: supplier.id,
              amount: amount,
              source: source
            )
            imported += 1
          rescue ActiveRecord::RecordNotFound
            missing << raw_name
          end
        end

        raise StandardError, "No se encontraron proveedores: #{missing.uniq.join(", ")}" if missing.any?
        raise StandardError, "El archivo de proveedores no tiene filas válidas." if imported.zero?
      end

      def import_sellers(io)
        OpeningBalance.users.delete_all
        missing = []
        imported = 0

        each_row(io) do |row, source|
          raw_name = row["Nombre"] || row["nombre"]
          amount = parse_amount(row["Total de comisión"] || row["total de comisión"] || row["Total"] || row["total"])
          next if raw_name.blank? || amount.zero?

          begin
            user = find_user(raw_name)
            OpeningBalance.create!(
              reference_type: OpeningBalance::TYPES[:user],
              reference_id: user.id,
              amount: amount,
              source: source
            )
            imported += 1
          rescue ActiveRecord::RecordNotFound
            missing << raw_name
          end
        end

        raise StandardError, "No se encontraron vendedores: #{missing.uniq.join(", ")}" if missing.any?
        raise StandardError, "El archivo de vendedores no tiene filas válidas." if imported.zero?
      end

      def each_row(io)
        return unless io
        source_name = filename_for(io)
        rows = extract_rows(io)
        rows.each { |row| yield(row, source_name) }
      end

      def filename_for(io)
        return io.original_filename if io.respond_to?(:original_filename)
        return io.path if io.respond_to?(:path)
        io.to_s
      end

      def extract_rows(io)
        file = io.respond_to?(:read) ? io : File.open(io)
        file.rewind if file.respond_to?(:rewind)
        name = filename_for(io).to_s.downcase
        if name.end_with?(".xlsx")
          extract_xlsx_rows(file)
        else
          extract_csv_rows(file)
        end
      end

      def extract_csv_rows(file)
        CSV.new(file, headers: true).map { |row| row.to_h }
      end

      def extract_xlsx_rows(file)
        xlsx = Roo::Spreadsheet.open(file, extension: :xlsx)
        sheet = xlsx.sheet(0)
        collected = []
        sheet.each_with_index(headers: true) do |row, idx|
          next if idx.zero? # saltar encabezados
          next if row.values.compact.empty?
          collected << row.transform_keys { |k| k.to_s }
        end
        collected
      end

      def parse_amount(value)
        return 0.to_d if value.blank?
        BigDecimal(value.to_s.tr(",", ""))
      rescue ArgumentError
        raise ArgumentError, "Monto inválido: #{value.inspect}"
      end

      def find_customer(token)
        t = token.to_s.strip
        by_code = Customer.find_by(code: t)
        return by_code if by_code
        by_name = Customer.find_by("lower(name) = ?", t.downcase)
        return by_name if by_name

        raise ActiveRecord::RecordNotFound, "Cliente no encontrado: #{t}"
      end

      def find_supplier(token)
        t = token.to_s.strip
        by_code = Supplier.find_by(code: t)
        return by_code if by_code
        by_name = Supplier.find_by("lower(name) = ?", t.downcase)
        return by_name if by_name

        raise ActiveRecord::RecordNotFound, "Proveedor no encontrado: #{t}"
      end

      def find_user(token)
        t = token.to_s.strip
        by_email = User.find_by(email: t)
        return by_email if by_email
        by_name = User.find_by("lower(name) = ?", t.downcase)
        return by_name if by_name

        raise ActiveRecord::RecordNotFound, "Vendedor no encontrado: #{t}"
      end
    end
  end
end
