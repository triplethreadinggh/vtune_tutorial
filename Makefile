CC = gcc
CCFLAGS = -O3 -g -fno-omit-frame-pointer -std=c17
OMPFLAGS = -fopenmp

SRC_DIR = src
BUILD_DIR = build

TARGETS = $(BUILD_DIR)/matrix_naive \
          $(BUILD_DIR)/matrix_blocked \
          $(BUILD_DIR)/matrix_parallel

.PHONY: all clean

all: $(BUILD_DIR) $(TARGETS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/matrix_naive: $(SRC_DIR)/matrix_naive.c
	$(CC) $(CCFLAGS) $< -o $@

$(BUILD_DIR)/matrix_blocked: $(SRC_DIR)/matrix_blocked.c
	$(CC) $(CCFLAGS) $< -o $@

$(BUILD_DIR)/matrix_parallel: $(SRC_DIR)/matrix_parallel.c
	$(CC) $(CCFLAGS) $(OMPFLAGS) $< -o $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: test
test: all
	@echo "=== Testing Naive Implementation ==="
	@$(BUILD_DIR)/matrix_naive 512
	@echo ""
	@echo "=== Testing Blocked Implementation ==="
	@$(BUILD_DIR)/matrix_blocked 512 64
	@echo ""
	@echo "=== Testing Parallel Implementation ==="
	@$(BUILD_DIR)/matrix_parallel 512 64 4
