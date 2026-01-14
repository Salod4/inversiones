class SuppliersController < ApplicationController
  before_action :set_supplier, only: [ :show, :edit, :update, :destroy ]

  def index
    suppliers = Supplier.all.to_a
    balances = suppliers.index_with { |supplier| supplier.available_transfer_total }
    sorted_suppliers = suppliers.sort_by { |supplier| -balances[supplier].to_d }
    @supplier_balances = balances.transform_keys(&:id)
    @suppliers_total_pending = balances.values.sum.to_d
    @pagy, @suppliers = pagy_array(sorted_suppliers)
  end

  def show
    @supplier_total_deposit = @supplier.sales.sum(:gross_deposit).to_d
    @supplier_total_ret_comp = @supplier.sales.sum("COALESCE(gross_deposit,0) - COALESCE(provider_commission,0)").to_d
    @supplier_total_transferred = @supplier.transfers.sum(&:total_outgoing).to_d
    @supplier_opening_balance = OpeningBalance.total_for_supplier(@supplier.id)
    @supplier_available_balance = @supplier_total_ret_comp + @supplier_opening_balance - @supplier_total_transferred


    @sales = @supplier.sales
                      .includes(:customer)
                      .order(date: :desc)
                      .limit(25)

    @supplier_transfers = @supplier.transfers
                                  .includes(:sale)
                                  .order(occurred_at: :desc)
  end

  def new
    @supplier = Supplier.new
  end

  def edit; end

  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save
      redirect_to @supplier, notice: "Supplier was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to @supplier, notice: "Supplier was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @supplier.destroy
      redirect_to suppliers_url, notice: "Supplier was successfully destroyed."
    else
      redirect_to suppliers_url, alert: @supplier.errors.full_messages.to_sentence
    end
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:code, :name, :default_analysis_pct)
  end
end
