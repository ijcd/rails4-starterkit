class User < ActiveRecord::Base
  include Concerns::UserImagesConcern

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :timeoutable, :lockable, :async

  has_many :authentications, dependent: :destroy, validate: false

  def display_name
    first_name.presence || email
  end

  # Override Devise to allow for Authentication or password.
  #
  # An invalid authentication is allowed for a new record since the record
  # needs to first be saved before the authentication.user_id can be set.
  def password_required?
    (!persisted? && authentications.empty?) ||
    (persisted? && encrypted_password.blank? && authentications.present? && !authentications.find{|a| a.valid?}) ||
    !password.nil? || !password_confirmation.nil?
  end

  # Merge attributes from Authentication if User attribute is blank.
  #
  # If User has fields that do not match the Authentication field name,
  # modify this method as needed.
  def reverse_merge_attributes_from_auth(auth)
    auth.oauth_data.each do |k, v|
      self[k] = v if self.respond_to?("#{k}=") && self[k].blank?
    end
  end
end
