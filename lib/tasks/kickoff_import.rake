namespace :kickoff do
  desc "Import opening balances from CSV files. Usage: rake kickoff:import customers=clientes.csv suppliers=proveedores.csv sellers=vendedores.csv"
  task import: :environment do
    customers_file = ENV["customers"]
    suppliers_file = ENV["suppliers"]
    sellers_file   = ENV["sellers"]

    Kickoff::Importer.import(
      customers: file_io(customers_file),
      suppliers: file_io(suppliers_file),
      sellers: file_io(sellers_file)
    )

    puts "Kickoff import completed."
  end

  def file_io(path)
    return nil if path.blank?
    File.open(path)
  end
end
