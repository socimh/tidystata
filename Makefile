# Statart Testing Workflow Makefile
# Testing with testthat + Demo reports with actual function output

.PHONY: test test-results demo-reports test-full clean help list-tests

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

help:
	@echo "$(BLUE)Statart Testing Workflow$(RESET)"
	@echo ""
	@echo "$(GREEN)Testing:$(RESET)"
	@echo "  $(YELLOW)make test$(RESET)          - Run all testthat tests (standard)"
	@echo "  $(YELLOW)make test-results$(RESET)  - Run tests and collect results to .opencode/results/"
	@echo "  $(YELLOW)make test-<name>$(RESET)   - Run specific test file (e.g., make test-summ)"
	@echo ""
	@echo "$(GREEN)Demo Reports:$(RESET)"
	@echo "  $(YELLOW)make demo-reports$(RESET)  - Generate demo reports showing actual function output"
	@echo ""
	@echo "$(GREEN)Full Pipeline:$(RESET)"
	@echo "  $(YELLOW)make test-full$(RESET)     - Run tests AND generate demo reports"
	@echo ""
	@echo "$(GREEN)Utilities:$(RESET)"
	@echo "  $(YELLOW)make clean$(RESET)         - Preserve artifacts; show cleanup guidance"
	@echo "  $(YELLOW)make list-tests$(RESET)    - List all test files"
	@echo ""
	@echo "$(GREEN)Examples:$(RESET)"
	@echo "  make demo-reports   # Generate reports showing real function output"
	@echo "  make test-summ      # Run tests/testthat/test-summ.R only"

# Run standard testthat tests
test:
	@echo "$(BLUE)Running testthat tests...$(RESET)"
	python .opencode/workflows/verify_package.py

# Collect test results (both .Rds and .txt)
test-results:
	@echo "$(BLUE)Collecting test results...$(RESET)"
	python .opencode/workflows/verify_package.py --prefix .opencode/results/current

# Generate demo reports showing actual function output
demo-reports:
	@echo "$(BLUE)Generating demo reports with actual function output...$(RESET)"
	python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/demos
	@echo "$(GREEN)Reports saved to .opencode/reports/$(RESET)"

# Full pipeline: test results + demo reports
test-full: test-results demo-reports
	@echo "$(GREEN)Complete workflow finished!$(RESET)"
	@echo "Test results: .opencode/results/"
	@echo "Demo reports: .opencode/reports/"

# Run specific test file (e.g., make test-summ runs test-summ.R)
test-%:
	@echo "$(BLUE)Running test file: test-$*.R$(RESET)"
	python .opencode/workflows/verify_package.py --filter "$*"

# Preserve reports, results and local artifacts; deletion needs a reviewed list.
clean:
	@echo "No files removed. Reports, results, datasets and native artifacts are preserved."
	@echo "Review an exact artifact list and obtain maintainer approval before deleting files."

# List available test files
list-tests:
	@echo "$(BLUE)Available test files:$(RESET)"
	@ls -1 tests/testthat/test-*.R | sed 's/tests\/testthat\/test-/- /' | sed 's/.R$$//'
