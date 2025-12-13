# frozen_string_literal: true

class KickoffsController < ApplicationController
  def show
  end

  def create
    Kickoff::Importer.import(
      customers: params[:customers_file],
      suppliers: params[:suppliers_file],
      sellers: params[:sellers_file]
    )
    redirect_to kickoff_path, notice: "Kickoff cargado correctamente."
  rescue StandardError => e
    flash.now[:alert] = "Error al importar: #{e.message}"
    render :show, status: :unprocessable_entity
  end

  def template
    type = params[:type].to_s
    case type
    when "customers"
      send_data customers_template, filename: "plantilla_clientes.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when "suppliers"
      send_data suppliers_template, filename: "plantilla_proveedores.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when "sellers"
      send_data sellers_template, filename: "plantilla_vendedores.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    else
      head :bad_request
    end
  end

  private

  def customers_template
    workbook_with("Clientes") do |sheet|
      sheet.add_row %w[Cliente Total\ Cliente]

      groups = CustomerGroups.build(Customer.all)
      grouped_ids = groups.flat_map { |g| g[:customers].map(&:id) }

      groups.each do |g|
        sheet.add_row [ "GRUPO #{g[:name]}", nil ]
      end

      Customer.where.not(id: grouped_ids).order(:name).find_each do |c|
        sheet.add_row [ c.name, nil ]
      end
    end
  end

  def suppliers_template
    workbook_with("Proveedores") do |sheet|
      sheet.add_row [ "Proveedor", "Saldo pendiente" ]
      Supplier.order(:name).find_each do |s|
        sheet.add_row [ s.name, nil ]
      end
    end
  end

  def sellers_template
    workbook_with("Vendedores") do |sheet|
      sheet.add_row [ "Nombre", "Total de comisión" ]
      User.order(:name).find_each do |u|
        sheet.add_row [ u.name || u.email, nil ]
      end
    end
  end

  def workbook_with(title)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: title) do |sheet|
      yield(sheet)
    end
    package.to_stream.read
  end
end
