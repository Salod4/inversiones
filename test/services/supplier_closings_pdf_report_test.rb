require "test_helper"

class SupplierClosingsPdfReportTest < ActiveSupport::TestCase
  test "renders pdf" do
    closing = Closing.create!(business_date: Date.current, status: "open")
    supplier = Supplier.create!(code: "SUP1", name: "Supplier One")
    sc = SupplierClosing.create!(
      closing: closing,
      supplier: supplier,
      supplier_credit: 100,
      amount_owed_to_supplier: 50
    )

    pdf_data = SupplierClosings::PdfReport.render(sc)
    assert_kind_of String, pdf_data
    assert pdf_data.start_with?("%PDF"), "expected PDF to start with %PDF"
  end
end
