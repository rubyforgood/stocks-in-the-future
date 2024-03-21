class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :company_name
      t.json :company_info

      t.timestamps
    end
    add_index :companies, :company_name, unique: true
  end
end
