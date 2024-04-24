class Company < ApplicationRecord
  belongs_to :stock

  # Company model will take care of pulling the information from the API
  def get_company_info
    # Logic to pull company info from Alpha Vantage API
  end
end