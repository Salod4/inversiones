class User < ApplicationRecord
   # Include default devise modules. Others available are:
   # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
   devise :database_authenticatable, :recoverable, :rememberable, :validatable
   has_many :commission_defaults, dependent: :destroy

   attr_accessor :signup_code
end
