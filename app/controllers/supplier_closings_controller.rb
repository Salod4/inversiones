class SupplierClosingsController < ApplicationController
  before_action :set_closing
  before_action :set_supplier_closing, only: [ :show, :edit, :update, :destroy, :pdf, :weekly_pdf ]
  before_action :set_suppliers, only: [ :new, :create, :edit, :update ]

  def index
    @pagy, @supplier_closings = pagy(@closing.supplier_closings.includes(:supplier))
  end

  def show
    @sales     = @supplier_closing.sales_for_closing
    @transfers = @supplier_closing.transfers_without_sale_for_closing
    @totals    = @supplier_closing.totals
  end

  def new
    @supplier_closing = @closing.supplier_closings.new
  end

  def create
    @supplier_closing = @closing.supplier_closings.build(supplier_closing_params)
    if @supplier_closing.save
      redirect_to closing_path(@closing), notice: "Supplier closing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @supplier_closing.update(supplier_closing_params)
      redirect_to closing_path(@closing), notice: "Supplier closing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier_closing.destroy
    redirect_to closing_path(@closing), notice: "Supplier closing was successfully destroyed."
  end

  def pdf
    pdf_data = SupplierClosings::PdfReport.new(@supplier_closing).render
    filename = pdf_filename

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  def weekly_pdf
    end_date = @closing.business_date
    start_date = end_date - 6.days
    pdf_data = SupplierClosings::WeeklyPdfReport
      .new(@supplier_closing, start_date: start_date, end_date: end_date)
      .render
    filename = "supplier_weekly_#{@closing.id}_#{supplier_code}_#{start_date.strftime("%Y%m%d")}_#{end_date.strftime("%Y%m%d")}.pdf"

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def set_closing
    @closing = Closing.find(params[:closing_id])
  end

  def set_supplier_closing
    @supplier_closing = @closing.supplier_closings.find(params[:id])
  end

  def set_suppliers
    @suppliers = Supplier.order(:name)
  end

  def pdf_filename
    "supplier_closing_#{@closing.id}_#{supplier_code}.pdf"
  end

  def supplier_code
    @supplier_closing.supplier&.code.presence || @supplier_closing.supplier_id
  end

  def supplier_closing_params
    params.require(:supplier_closing).permit(:supplier_id, :supplier_credit, :amount_owed_to_supplier)
  end
end
