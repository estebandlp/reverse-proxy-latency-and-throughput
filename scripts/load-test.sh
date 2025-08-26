#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set server URL - defaults to using the Nginx proxy
HOST=${1:-"http://localhost:3000"}
CONCURRENCY=${2:-100}
REQUESTS=${3:-1000}

echo -e "${BLUE}=== Latency & Throughput Test ===${NC}"
echo -e "${BLUE}Host: ${HOST}${NC}"
echo -e "${BLUE}Concurrency: ${CONCURRENCY}${NC}"
echo -e "${BLUE}Total Requests: ${REQUESTS}${NC}"
echo ""

# Function to run benchmark on an endpoint
run_benchmark() {
    local endpoint=$1
    local description=$2
    
    echo -e "${GREEN}Testing ${description} - ${HOST}${endpoint}${NC}"
    echo -e "${GREEN}===============================================${NC}"
    
    # Run Apache Benchmark and save results
    ab -c ${CONCURRENCY} -n ${REQUESTS} "${HOST}${endpoint}" > "benchmarkResults/benchmark_${endpoint#/}.txt"
    
    # Extract and display key metrics
    REQUESTS_PER_SEC=$(grep "Requests per second" "benchmarkResults/benchmark_${endpoint#/}.txt" | awk '{print $4}')
    MEAN_LATENCY=$(grep "Time per request" "benchmarkResults/benchmark_${endpoint#/}.txt" | head -1 | awk '{print $4}')
    P95_LATENCY=$(grep "95%" "benchmarkResults/benchmark_${endpoint#/}.txt" | awk '{print $2}')
    
    echo -e "${BLUE}Results:${NC}"
    echo -e "- Throughput: ${GREEN}${REQUESTS_PER_SEC} requests/second${NC}"
    echo -e "- Mean Latency: ${GREEN}${MEAN_LATENCY} ms${NC}"
    echo -e "- P95 Latency: ${GREEN}${P95_LATENCY} ms${NC}"
    echo ""
    echo -e "Full results saved to: benchmarkResults/benchmark_${endpoint#/}.txt"
    echo ""
}

# Check if Apache Benchmark is installed
if ! command -v ab &> /dev/null; then
    echo -e "${RED}Error: Apache Benchmark (ab) is not installed.${NC}"
    echo -e "Please install it with: ${BLUE}sudo apt-get install apache2-utils${NC} (Ubuntu/Debian)"
    echo -e "Or: ${BLUE}brew install httpd${NC} (macOS)"
    exit 1
fi

# Run benchmarks on both endpoints
run_benchmark "/fast" "Fast Endpoint"
run_benchmark "/slow" "Slow Endpoint"

# Endpoints to demonstrate latency orders of magnitude
run_benchmark "/memory" "Memory-like Endpoint (1ms)"
run_benchmark "/database" "Database-like Endpoint (20ms)"

echo -e "${BLUE}=== Comparison Analysis ===${NC}"
FAST_RPS=$(grep "Requests per second" "benchmarkResults/benchmark_fast.txt" | awk '{print $4}')
SLOW_RPS=$(grep "Requests per second" "benchmarkResults/benchmark_slow.txt" | awk '{print $4}')
FAST_LATENCY=$(grep "Time per request" "benchmarkResults/benchmark_fast.txt" | head -1 | awk '{print $4}')
SLOW_LATENCY=$(grep "Time per request" "benchmarkResults/benchmark_slow.txt" | head -1 | awk '{print $4}')

# Calculate throughput difference
THROUGHPUT_DIFF=$(echo "scale=2; ($FAST_RPS - $SLOW_RPS) / $SLOW_RPS * 100" | bc)
LATENCY_DIFF=$(echo "scale=2; ($SLOW_LATENCY - $FAST_LATENCY) / $FAST_LATENCY * 100" | bc)

echo -e "- The slow endpoint has ${RED}${THROUGHPUT_DIFF}% lower throughput${NC} than the fast endpoint."
echo -e "- The slow endpoint has ${RED}${LATENCY_DIFF}% higher latency${NC} than the fast endpoint."
echo ""
echo -e "${GREEN}This demonstrates how latency directly impacts overall system throughput.${NC}"
echo -e "${GREEN}When latency increases, the system can handle fewer requests per second.${NC}" 