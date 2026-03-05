class SalesUsersController < ApplicationController
  before_action :set_sale, except: [ :index ]
  before_action :set_sales_user, only: [ :destroy ]
  before_action :set_users, only: [ :new, :create ]

  def index
    @pagy, @sales_users = pagy(SalesUser.includes(:user, sale: :supplier).order(created_at: :desc))
    @totals_by_user = User.balances_by_user.reject { |_, total| total.to_d.zero? }
    ids = @totals_by_user.keys + @sales_users.map(&:user_id)
    @users = User.where(id: ids).index_by(&:id)
  end

  def new
    @sales_user = @sale.sales_users.build
  end

  def create
    @sales_user = @sale.sales_users.build(sales_user_params)
    if @sales_user.save
      redirect_to sale_path(@sale), notice: "Sales user was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @sales_user.destroy
      redirect_to sale_path(@sale), notice: "Sales user was successfully removed."
    else
      redirect_to sale_path(@sale), alert: @sales_user.errors.full_messages.to_sentence
    end
  end

  private

  def set_sale
    @sale = Sale.find(params[:sale_id])
  end

  def set_sales_user
    @sales_user = @sale.sales_users.find(params[:id])
  end

  def set_users
    @users = User.order(:email)
  end

  def sales_user_params
    params.require(:sales_user).permit(
      :user_id,
      :commission_pct,
      :commission_pct_override,
      :commission_amount
    )
  end
end
