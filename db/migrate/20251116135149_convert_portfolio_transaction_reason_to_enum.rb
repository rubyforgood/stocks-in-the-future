class ConvertPortfolioTransactionReasonToEnum < ActiveRecord::Migration[8.1]
  def up
    add_column :portfolio_transactions, :reason_enum, :integer

    safety_assured do
      execute <<-SQL
        UPDATE portfolio_transactions SET reason_enum = 0 WHERE reason = 'Earnings from Math';
        UPDATE portfolio_transactions SET reason_enum = 1 WHERE reason = 'Earnings from Reading';
        UPDATE portfolio_transactions SET reason_enum = 2 WHERE reason = 'Earnings from Attendance';
        UPDATE portfolio_transactions SET reason_enum = 3 WHERE reason = 'Earnings from Grades';
        UPDATE portfolio_transactions SET reason_enum = 4 WHERE reason = 'Transaction Fees';
        UPDATE portfolio_transactions SET reason_enum = 5 WHERE reason = 'Award';
        UPDATE portfolio_transactions SET reason_enum = 6 WHERE reason = 'Administrative Adjustment';
      SQL
    end

    if PortfolioTransaction.where.not(reason: nil).where(reason_enum: nil).exists?
      raise "Migration Failed: Some records were not migrated! Check for unmapped 'reason' strings."
    end

    safety_assured do
      remove_column :portfolio_transactions, :reason
    end

    safety_assured do
      rename_column :portfolio_transactions, :reason_enum, :reason
    end
  end

  def down
    add_column :portfolio_transactions, :reason_string, :string

    safety_assured do
      execute <<-SQL
        UPDATE portfolio_transactions SET reason_string = 'Earnings from Math' WHERE reason = 0;
        UPDATE portfolio_transactions SET reason_string = 'Earnings from Reading' WHERE reason = 1;
        UPDATE portfolio_transactions SET reason_string = 'Earnings from Attendance' WHERE reason = 2;
        UPDATE portfolio_transactions SET reason_string = 'Earnings from Grades' WHERE reason = 3;
        UPDATE portfolio_transactions SET reason_string = 'Transaction Fees' WHERE reason = 4;
        UPDATE portfolio_transactions SET reason_string = 'Award' WHERE reason = 5;
        UPDATE portfolio_transactions SET reason_string = 'Administrative Adjustment' WHERE reason = 6;
      SQL
    end

    safety_assured do
      remove_column :portfolio_transactions, :reason
    end

    safety_assured do
      rename_column :portfolio_transactions, :reason_string, :reason
    end
  end
end
