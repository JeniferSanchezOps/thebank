CREATE TABLE IF NOT EXISTS credit_applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_sid VARCHAR(255) NOT NULL,
    account_id VARCHAR(255) NOT NULL,
    monthly_income DECIMAL(15,2) NOT NULL,
    monthly_expenses DECIMAL(15,2) NOT NULL,
    dependents INT NOT NULL,
    requested_amount DECIMAL(15,2) NOT NULL,
    application_date DATETIME NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS credits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_sid VARCHAR(255) NOT NULL,
    balance DECIMAL(15,2) NOT NULL,
    principal_amount DECIMAL(15,2) NOT NULL,
    start_date DATETIME NOT NULL,
    term INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add some test data
INSERT INTO credits (account_sid, balance, principal_amount, start_date, term)
VALUES 
('test-account-123', 4500.00, 5000.00, '2025-01-15 00:00:00', 12),
('test-account-123', 9800.00, 10000.00, '2024-11-01 00:00:00', 24);
