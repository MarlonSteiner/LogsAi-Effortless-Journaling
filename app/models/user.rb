class User < ApplicationRecord
  # Included default devise modules
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable

  # Associations
  has_many :journal_entries

  # Validations
  # validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  # validates :surname, presence: true, length: { minimum: 2, maximum: 50 }

  # Instance methods
  def full_name
    "#{name} #{surname}".strip
  end

  def first_name
    name
  end

  # Logo
  def logo_initial
    first_name.present? ? first_name[0].upcase : "U"
  end
end
