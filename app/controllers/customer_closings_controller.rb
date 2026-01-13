class CustomerClosingsController < ApplicationController
  before_action :set_closing
  before_action :set_customer_closing, only: [ :show, :edit, :update, :destroy, :pdf, :weekly_pdf ]
  before_action :set_customers, only: [ :new, :create, :edit, :update ]

  def index
    @pagy, @customer_closings = pagy(@closing.customer_closings.includes(:customer))
  end

  def group
    group = CustomerGroups.find_by_name(params[:name], Customer.all)
    @group_name = group&.dig(:name)
    customer_ids = group ? group[:customers].map(&:id) : []

    @customer_closings = @closing.customer_closings.includes(:customer)
    @customer_closings = @customer_closings.where(customer_id: customer_ids) if customer_ids.present?
    @group_total = @customer_closings.sum(:customer_balance)
  end

  def show
    @sales  = @customer_closing.sales_for_closing
    @totals = @customer_closing.totals
  end

  def new
    @customer_closing = @closing.customer_closings.new
  end

  def create
    @customer_closing = @closing.customer_closings.build(customer_closing_params)
    if @customer_closing.save
      redirect_to closing_path(@closing), notice: "Customer closing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @customer_closing.update(customer_closing_params)
      redirect_to closing_path(@closing), notice: "Cierre de cliente actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer_closing.destroy
    redirect_to closing_path(@closing), notice: "Customer closing was successfully destroyed."
  end

  def pdf
    pdf_data = CustomerClosings::PdfReport.new(@customer_closing).render
    filename = "customer_closing_#{@closing.id}_#{@customer_closing.customer_id}.pdf"

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  def weekly_pdf
    end_date = @closing.business_date
    start_date = end_date - 6.days
    pdf_data = CustomerClosings::WeeklyPdfReport
      .new(@customer_closing, start_date: start_date, end_date: end_date)
      .render
    filename = "customer_weekly_#{@closing.id}_#{@customer_closing.customer_id}_#{start_date.strftime("%Y%m%d")}_#{end_date.strftime("%Y%m%d")}.pdf"

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def set_closing
    @closing = Closing.find(params[:closing_id])
  end

  def set_customer_closing
    @customer_closing = @closing.customer_closings.find(params[:id])
  end

  def set_customers
    @customers = Customer.order(:name)
  end

  def customer_closing_params
    params.require(:customer_closing).permit(:customer_id, :customer_balance, :receivables)
  end
end
