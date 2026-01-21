class User < ApplicationRecord
   # Include default devise modules. Others available are:
   # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
   devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
   has_many :commission_defaults, dependent: :destroy
   has_many :customer_supplier_vendors, dependent: :destroy, inverse_of: :user

   attr_accessor :signup_code
end
