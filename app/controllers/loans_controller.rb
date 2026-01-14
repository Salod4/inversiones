class LoansController < ApplicationController
  before_action :set_loan, only: [ :show, :edit, :update, :destroy ]
  before_action :set_available_to_lend, only: [ :new, :create, :edit, :update ]

  def index
    @loans = Loan.where("COALESCE(loans.amount,0) > COALESCE(loans.total_paid,0)")
                 .order(created_at: :desc)
                 .includes(:loan_payments)
    @loan_totals = {
      amount: Loan.sum(:amount),
      paid: Loan.sum(:total_paid),
      outstanding: @loans.sum(&:balance)
    }
  end

  def show
    @payment = @loan.loan_payments.build
    @payments = @loan.loan_payments.order(paid_at: :desc, created_at: :desc)
  end

  def new
    @loan = Loan.new
  end

  def edit; end

  def create
    @loan = Loan.new(loan_params)
    if @loan.save
      redirect_to loans_path, notice: "Prestamo creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @loan.update(loan_params)
      redirect_to loan_path(@loan), notice: "Prestamo actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @loan.destroy
      redirect_to loans_path, notice: "Prestamo eliminado."
    else
      redirect_to loans_path, alert: @loan.errors.full_messages.to_sentence
    end
  end

  private

  def set_loan
    @loan = Loan.find(params[:id])
  end

  def set_available_to_lend
    total_suppliers = Supplier.all.sum(&:available_transfer_total).to_d
    outstanding_all = Loan.sum(Arel.sql("COALESCE(amount,0) - COALESCE(total_paid,0)")).to_d
    current_balance = (defined?(@loan) && @loan&.persisted?) ? @loan.balance.to_d : 0.to_d
    outstanding_others = outstanding_all - current_balance
    @available_to_lend = total_suppliers - outstanding_others
  end

  def loan_params
    params.require(:loan).permit(:name, :amount, :note)
  end
end
