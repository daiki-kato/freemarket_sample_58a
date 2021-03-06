class User < ApplicationRecord

  has_many :sns_credentials, dependent: :destroy
  has_many :products,dependent: :destroy
  has_many :cards,dependent: :destroy
  has_many :addresses,dependent: :destroy
  has_many :comments 

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[facebook google_oauth2]
         kanji = /\A[一-龥]+\z/
         kana = /\A([ァ-ン]|ー)+\z/
         year_month_day = /\A\d{4}-\d{2}-\d{2}\z/

  validates :nickname, presence: true, length: { maximum: 15 },profanity_filter: true
  validates :f_name_kanji, presence: true, length: { maximum: 15 }, format: { with: kanji }
  validates :l_name_kanji, presence: true, length: { maximum: 15 }, format: { with: kanji }
  validates :f_name_kana, presence: true, length: { maximum: 15 }, format: { with: kana }
  validates :l_name_kana, presence: true, length: { maximum: 15 }, format: { with: kana }
  validates :birthday, presence: true, format: { with: year_month_day }
  validates :password,presence: true
  validates :password_confirmation,presence: true
  validates :tel, presence: true

  
#oauth認証メソッド
  def self.without_sns_data(auth)
    user = User.where(email: auth.info.email).first

      if user.present?
        sns = SnsCredential.create(
          uid: auth.uid,
          provider: auth.provider,
          user_id: user.id
        )
      else
        user = User.new(
          nickname: auth.info.name,
          email: auth.info.email,
          password: Devise.friendly_token.first(7)
        )
        sns = SnsCredential.new(
          uid: auth.uid,
          provider: auth.provider
        )
      end
      return { user: user ,sns: sns}
    end

   def self.with_sns_data(auth, snscredential)
    user = User.where(id: snscredential.user_id).first
    unless user.present?
      user = User.new(
        nickname: auth.info.name,
        email: auth.info.email,
        password: Devise.friendly_token.first(7)
      )
    end
    return {user: user}
   end

   def self.find_oauth(auth)
    uid = auth.uid
    provider = auth.provider
    snscredential = SnsCredential.where(uid: uid, provider: provider).first
    if snscredential.present?
      user = with_sns_data(auth, snscredential)[:user]
      sns = snscredential
    else
      user = without_sns_data(auth)[:user]
      sns = without_sns_data(auth)[:sns]
    end
    return { user: user ,sns: sns}
  end

end
