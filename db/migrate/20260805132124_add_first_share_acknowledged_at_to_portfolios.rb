class AddFirstShareAcknowledgedAtToPortfolios < ActiveRecord::Migration[8.1]
  def change
    # Nullable, and a timestamp rather than a boolean: "when did this student acknowledge owning
    # their first share" answers the same question as a flag and also says when, which is the
    # difference between a feature flag and a fact. Null means not yet acknowledged.
    add_column :portfolios, :first_share_acknowledged_at, :datetime
  end
end
