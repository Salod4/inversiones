class DailyBalanceEmailJob < ApplicationJob
  queue_as :default

  def perform
    mail = DailyBalancesMailer.summary
    return unless mail

    mail.deliver_now
  end
end
