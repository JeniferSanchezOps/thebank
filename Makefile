.PHONY: setup build start stop restart logs clean test mysql-shell init-db status help

# Colors for terminal output
GREEN := \033[0;32m
YELLOW := \033[1;33m
CYAN := \033[0;36m
RED := \033[0;31m
NC := \033[0m # No Color

# Project settings
PROJECT_NAME := credit-system
DOCKER_COMPOSE := docker-compose
PYTHON := python3
PIP := pip3

help: ## Show this help message
	@echo "$(YELLOW)Credit System Management$(NC)"
	@echo "$(CYAN)Usage: make [target]$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## Setup project for first time use
	@echo "$(YELLOW)Setting up project environment...$(NC)"
	@mkdir -p credit-application-service
	@mkdir -p credit-info-service
	@mkdir -p mysql/init
	@echo "$(GREEN)Creating requirements.txt...$(NC)"
	@echo "Flask==2.2.3\nflask-cors==3.0.10\nmysql-connector-python==8.0.32\npython-dotenv==1.0.0" > credit-application-service/requirements.txt
	@cp credit-application-service/requirements.txt credit-info-service/requirements.txt
	@echo "$(GREEN)Creating .env file...$(NC)"
	@echo "# Set to 'mysql' for local Docker development\n# For RDS, change to your AWS RDS endpoint\nDB_HOST=mysql\nDB_NAME=credit_db\nDB_USER=credit_user\nDB_PASSWORD=credit_password\nDB_PORT=3306" > .env
	@echo "$(GREEN)Creating MySQL init script...$(NC)"
	@echo "CREATE TABLE IF NOT EXISTS credit_applications (\n    id INT AUTO_INCREMENT PRIMARY KEY,\n    account_sid VARCHAR(255) NOT NULL,\n    account_id VARCHAR(255) NOT NULL,\n    monthly_income DECIMAL(15,2) NOT NULL,\n    monthly_expenses DECIMAL(15,2) NOT NULL,\n    dependents INT NOT NULL,\n    requested_amount DECIMAL(15,2) NOT NULL,\n    application_date DATETIME NOT NULL,\n    status VARCHAR(50) DEFAULT 'pending',\n    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n);\n\nCREATE TABLE IF NOT EXISTS credits (\n    id INT AUTO_INCREMENT PRIMARY KEY,\n    account_sid VARCHAR(255) NOT NULL,\n    balance DECIMAL(15,2) NOT NULL,\n    principal_amount DECIMAL(15,2) NOT NULL,\n    start_date DATETIME NOT NULL,\n    term INT NOT NULL,\n    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n);\n\n-- Add some test data\nINSERT INTO credits (account_sid, balance, principal_amount, start_date, term)\nVALUES \n('test-account-123', 4500.00, 5000.00, '2025-01-15 00:00:00', 12),\n('test-account-123', 9800.00, 10000.00, '2024-11-01 00:00:00', 24);" > mysql/init/01-init.sql
	@echo "$(GREEN)Setup completed successfully!$(NC)"

build: ## Build Docker images
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build completed successfully!$(NC)"

start: ## Start all services
	@echo "$(YELLOW)Starting services...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Services started successfully!$(NC)"
	@echo "Credit Application Service: http://localhost:10001/accounts/{account_sid}/credit-applications"
	@echo "Credit Info Service: http://localhost:10002/accounts/{account_sid}/credits"

stop: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Services stopped successfully!$(NC)"

restart: stop start ## Restart all services

logs: ## Show logs from all services
	@$(DOCKER_COMPOSE) logs -f

clean: ## Clean up containers, volumes, and images
	@echo "$(YELLOW)Cleaning up project...$(NC)"
	@$(DOCKER_COMPOSE) down -v --rmi local
	@echo "$(GREEN)Cleanup completed successfully!$(NC)"

test: ## Run tests
	@echo "$(YELLOW)Running tests...$(NC)"
	@echo "$(CYAN)Not implemented yet. Add your test commands here.$(NC)"

#mysql-shell: ## Open MySQL shell in the container
#	@echo "$(YELLOW)Opening MySQL shell...$(NC)"
#	@$(DOCKER_COMPOSE) exec mysql mysql -u credit_user -pcredit_password credit_db

#init-db: ## Initialize the database with sample data
#	@echo "$(YELLOW)Initializing database...$(NC)"
#	@$(DOCKER_COMPOSE) exec mysql sh -c "mysql -u credit_user -pcredit_password credit_db < /docker-entrypoint-initdb.d/01-init.sql"
#	@echo "$(GREEN)Database initialized successfully!$(NC)"

status: ## Check status of services
	@echo "$(YELLOW)Service status:$(NC)"
	@$(DOCKER_COMPOSE) ps

dev-local: ## Start development environment without Docker (requires local MySQL)
	@echo "$(YELLOW)Starting development environment locally...$(NC)"
	@echo "$(CYAN)Starting Credit Application Service on port 10001...$(NC)"
	@cd credit-application-service && $(PYTHON) app.py &
	@echo "$(CYAN)Starting Credit Info Service on port 10002...$(NC)"
	@cd credit-info-service && $(PYTHON) app.py &
	@echo "$(GREEN)Services started in background. Use 'fg' to bring to foreground.$(NC)"

install-deps: ## Install Python dependencies locally
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	@cd credit-application-service && $(PIP) install -r requirements.txt
	@cd credit-info-service && $(PIP) install -r requirements.txt
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"
# Testing endpoints
test-app-service: ## Test credit application service
	@echo "$(YELLOW)Testing credit application service...$(NC)"
	@curl -s -X POST -H "Content-Type: application/json" -d '{"accountId": "user123", "monthlyIncome": 5000, "monthlyExpenses": 2000, "dependents": 2, "requestedAmount": 10000}' http://localhost:$(APP_PORT)/accounts/$(TEST_ACCOUNT)/credit-applications | jq || echo "$(RED)Failed to connect to credit application service. Make sure the service is running and jq is installed.$(NC)"

test-info-service: ## Test credit info service
	@echo "$(YELLOW)Testing credit info service...$(NC)"
	@curl -s http://localhost:$(INFO_PORT)/accounts/$(TEST_ACCOUNT)/credits | jq || echo "$(RED)Failed to connect to credit info service. Make sure the service is running and jq is installed.$(NC)"

# Fetch data from services
fetch-app-service: ## Fetch from credit application service
	@echo "$(YELLOW)Fetching from credit application service...$(NC)"
	@echo "$(CYAN)This is a POST endpoint. Using test data to submit a credit application...$(NC)"
	@curl -s -X POST -H "Content-Type: application/json" \
		-d '{"accountId": "user123", "monthlyIncome": 5000, "monthlyExpenses": 2000, "dependents": 2, "requestedAmount": 10000}' \
		http://localhost:$(APP_PORT)/accounts/$(TEST_ACCOUNT)/credit-applications | jq || \
		echo "$(RED)Failed to connect to credit application service. Make sure the service is running.$(NC)"

fetch-info-service: ## Fetch from credit info service
	@echo "$(YELLOW)Fetching from credit info service...$(NC)"
	@curl -s http://localhost:$(INFO_PORT)/accounts/$(TEST_ACCOUNT)/credits | jq || \
		echo "$(RED)Failed to connect to credit info service. Make sure the service is running.$(NC)"

# All-in-one setup and test
deploy-and-test: setup-local build-local start-local ## Deploy and test all services
	@echo "$(YELLOW)Waiting for services to fully start...$(NC)"
	@sleep 10
	@make fetch-app-service
	@make fetch-info-service
	@echo "$(GREEN)All services are up and running!$(NC)"