class SupplierClosingsController < ApplicationController
  before_action :set_closing
  before_action :set_supplier_closing, only: [ :show, :edit, :update, :destroy ]
  before_action :set_suppliers, only: [ :new, :create, :edit, :update ]

  def index
    @supplier_closings = @closing.supplier_closings.includes(:supplier)
  end

  def show; end

  def new
    @supplier_closing = @closing.supplier_closings.build
  end

  def edit; end

  def create
    @supplier_closing = @closing.supplier_closings.build(supplier_closing_params)
    if @supplier_closing.save
      redirect_to closing_path(@closing), notice: "Supplier closing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @supplier_closing.update(supplier_closing_params)
      redirect_to closing_path(@closing), notice: "Supplier closing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @supplier_closing.destroy
      redirect_to closing_path(@closing), notice: "Supplier closing was successfully destroyed."
    else
      redirect_to closing_path(@closing), alert: @supplier_closing.errors.full_messages.to_sentence
    end
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

  def supplier_closing_params
    params.require(:supplier_closing).permit(:supplier_id, :supplier_credit, :amount_owed_to_supplier)
  end
end
