CC = gcc
ICX = icx

CC_FLAGS = -O3 -g -fno-omit-frame-pointer -std=c17
ICX_FLAGS = -O3 -g -fno-omit-frame-pointer

CC_OMPFLAGS = -fopenmp
ICX_OMPFLAGS = -qopenmp

SRC_DIR = src
BUILD_DIR = build

CC_TARGETS = $(BUILD_DIR)/matrix_naive \
             $(BUILD_DIR)/matrix_blocked \
             $(BUILD_DIR)/matrix_parallel

ICX_TARGETS = $(BUILD_DIR)/matrix_naive_icx \
	      $(BUILD_DIR)/matrix_blocked_icx \
	      $(BUILD_DIR)/matrix_parallel_icx
 
.PHONY: all clean gcc icx

all: $(BUILD_DIR) gcc icx

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

gcc: $(BUILD_DIR) $(CC_TARGETS)

$(BUILD_DIR)/matrix_naive: $(SRC_DIR)/matrix_naive.c
	$(CC) $(CC_FLAGS) $< -o $@

$(BUILD_DIR)/matrix_blocked: $(SRC_DIR)/matrix_blocked.c
	$(CC) $(CC_FLAGS) $< -o $@

$(BUILD_DIR)/matrix_parallel: $(SRC_DIR)/matrix_parallel.c
	$(CC) $(CC_FLAGS) $(CC_OMPFLAGS) $< -o $@

icx: $(BUILD_DIR) $(ICX_TARGETS)

$(BUILD_DIR)/matrix_naive_icx: $(SRC_DIR)/matrix_naive.c
	$(ICX) $(ICX_FLAGS) $< -o $@

$(BUILD_DIR)/matrix_blocked_icx: $(SRC_DIR)/matrix_blocked.c
	$(ICX) $(ICX_FLAGS) $< -o $@

$(BUILD_DIR)/matrix_parallel_icx: $(SRC_DIR)/matrix_parallel.c
	$(ICX) $(ICX_FLAGS) $(ICX_OMPFLAGS) $< -o $@

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
			
	@echo "=== Testing ICX Naive Implementation ==="
	@$(BUILD_DIR)/matrix_naive_icx 512
	@echo ""
	@echo "=== Testing ICX Blocked Implementation ==="
	@$(BUILD_DIR)/matrix_blocked_icx 512 64
	@echo ""
	@echo "=== Testing ICX Parallel Implementation ==="
	@$(BUILD_DIR)/matrix_parallel_icx 512 64 4

