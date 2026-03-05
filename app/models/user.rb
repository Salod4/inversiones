class User < ApplicationRecord
   # Include default devise modules. Others available are:
   # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
   devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
   has_many :commission_defaults, dependent: :destroy
   has_many :customer_supplier_vendors, dependent: :destroy, inverse_of: :user

   attr_accessor :signup_code

   def self.balances_by_user(user_ids = nil)
     ids = Array(user_ids).compact
     ids = User.pluck(:id) if ids.empty?
     return {} if ids.empty?

     commissions = SalesUser.where(user_id: ids).group(:user_id).sum(:commission_amount)
     openings = OpeningBalance.users.where(reference_id: ids).group(:reference_id).sum(:amount)
     incoming = Transfer.incoming_sum_by_user(ids)
     outgoing = Transfer.outgoing_sum_by_user(ids)

     ids.index_with do |uid|
       commissions.fetch(uid, 0).to_d +
         openings.fetch(uid, 0).to_d +
         incoming.fetch(uid, 0).to_d -
         outgoing.fetch(uid, 0).to_d
     end
   end
end
