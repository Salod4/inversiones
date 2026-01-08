class LoanPaymentsController < ApplicationController
  before_action :set_loan

  def create
    payment = @loan.loan_payments.new(payment_params)
    if payment.save
      redirect_to request.referer.presence || loan_path(@loan), notice: "Pago registrado."
    else
      redirect_to request.referer.presence || loan_path(@loan), alert: payment.errors.full_messages.to_sentence
    end
  end

  def destroy
    payment = @loan.loan_payments.find(params[:id])
    if payment.destroy
      redirect_to request.referer.presence || loan_path(@loan), notice: "Pago eliminado."
    else
      redirect_to request.referer.presence || loan_path(@loan), alert: payment.errors.full_messages.to_sentence
    end
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def payment_params
    params.require(:loan_payment).permit(:amount, :paid_at)
  end
end
