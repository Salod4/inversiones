class ClosingsController < ApplicationController
  before_action :set_closing, only: [ :show, :edit, :update, :destroy ]

  def index
    @closings = Closing.order(business_date: :desc)
  end

  def show
    @customer_closings = @closing.customer_closings.includes(:customer)
    @supplier_closings = @closing.supplier_closings.includes(:supplier)
  end

  def new
    @closing = Closing.new
  end

  def edit; end

  def create
    @closing = Closing.new(closing_params)
    if @closing.save
      redirect_to @closing, notice: "Closing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @closing.update(closing_params)
      redirect_to @closing, notice: "Closing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @closing.destroy
      redirect_to closings_url, notice: "Closing was successfully destroyed."
    else
      redirect_to closings_url, alert: @closing.errors.full_messages.to_sentence
    end
  end

  private

  def set_closing
    @closing = Closing.find(params[:id])
  end

  def closing_params
    params.require(:closing).permit(
      :business_date,
      :closed_at,
      :status,
      :total_customers,
      :total_suppliers,
      :difference
    )
  end
end
