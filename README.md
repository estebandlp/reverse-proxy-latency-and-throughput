# Latency vs Throughput Demonstration

This project provides a practical demonstration of the difference between latency and throughput in a web application, using Node.js with Express and Nginx as a reverse proxy.

## Concepts

### What is Latency?

**Latency** is the time it takes for a single request to travel from the client to the server and back again. It's essentially the *delay* between a request and its response.

- **Units**: Measured in time (milliseconds, seconds)
- **Lower is better**: Lower latency means faster response times
- **Affected by**: Network distance, processing time, server load, I/O operations

### What is Throughput?

**Throughput** is the number of requests a system can handle in a given time period. It's the *capacity* of your system to process multiple requests.

- **Units**: Measured in requests per second (RPS), transactions per second (TPS)
- **Higher is better**: Higher throughput means more capacity
- **Affected by**: Server resources, code efficiency, database performance, latency

### The Relationship

Latency and throughput are inversely related. As latency increases, throughput often decreases. This is because high latency means each request takes longer to process, reducing the total number of requests that can be handled in a given time period.

## Project Structure

```
├── config/
│   └── nginx.conf          # Nginx configuration for reverse proxy
├── scripts/
│   └── load-test.sh       # Benchmark script
├── src/
│   ├── index.js           # Application entry point
│   └── server.js          # Express server implementation
├── package.json           # Project dependencies
└── README.md              # This file
```

## Architecture Overview

This project demonstrates latency and throughput concepts using a **reverse proxy architecture**:

```
Client → Nginx (Port 80) → Node.js (Port 3000)
```

### Why Use a Reverse Proxy?

1. **Real-world Simulation**: Most production applications use reverse proxies (Nginx, HAProxy, etc.)
2. **Additional Latency Layer**: Demonstrates how network hops affect performance
3. **Load Balancing Concepts**: Shows how proxies can distribute traffic
4. **Headers and Routing**: Illustrates how proxies modify requests

### Access Points

- **Direct to Node.js**: `http://localhost:3000/*` (bypasses proxy)
- **Through Nginx**: `http://localhost/*` (goes through proxy)

You can compare latencies between these two paths to see the proxy overhead.

## How to Run the Project

### Prerequisites

- Node.js (v18.11.0+)
- npm
- Nginx
- Apache Benchmark (`ab`) or wrk for load testing

### Step 1: Install Dependencies

```bash
npm install
```

### Step 2: Start the Node.js Server

For production:
```bash
npm start
```

For development (with auto-reload using Node.js native watch mode):
```bash
npm run dev
```

This will start the Express server on port 3000 with multiple endpoints demonstrating different latency scenarios:
- `/fast`: Responds immediately (baseline)
- `/slow`: Adds a 1-second artificial delay (high latency)
- `/memory`: Simulates memory access latency (1ms - RAM-like)
- `/database`: Simulates database query latency (20ms - HDD-like)

### Step 3: Configure and Start Nginx

Use the provided Makefile command to set up Nginx:

```bash
make setup-nginx
```

This will:
1. Copy the Nginx configuration file to the proper location
2. Enable the site configuration
3. Remove any conflicting default configurations
4. Restart Nginx

Alternatively, you can manually set up Nginx:

```bash
sudo cp config/nginx.conf /etc/nginx/sites-available/latency-demo.conf
sudo ln -sf /etc/nginx/sites-available/latency-demo.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

Nginx will now proxy requests from port 80 to your Node.js application on port 3000.

### Step 4: Run the Benchmark

```bash
make benchmark
```

Or run the script directly with custom parameters:

```bash
# Test using Nginx (port 80)
./scripts/load-test.sh http://localhost 100 1000

# Test directly against Node.js (port 3000)
./scripts/load-test.sh http://localhost:3000 100 1000
```

Arguments:
1. URL (default: http://localhost)
2. Concurrency level (default: 100)
3. Total requests (default: 1000)

### Step 5: Verify Reverse Proxy Setup

Test that the reverse proxy is working correctly:

```bash
# Test through Nginx (should show "Via Nginx: true")
curl http://localhost/health

# Test direct to Node.js (should show "Via Nginx: false")  
curl http://localhost:3000/health
```

### Step 6: Compare Latencies

Run benchmarks to compare direct vs proxy latencies:

```bash
# Test through Nginx (includes proxy overhead)
./scripts/load-test.sh http://localhost 10 100

# Test direct to Node.js (no proxy overhead)
./scripts/load-test.sh http://localhost:3000 10 100
```

The difference in latencies demonstrates the overhead added by the reverse proxy layer.

## Understanding the Results

The benchmark produces two key metrics:

1. **Throughput (Requests per second)**: The number of requests the system can handle per second.
2. **Latency (Time per request)**: The time taken for each request to complete.

### Expected Results

The benchmark demonstrates different latency scenarios that mirror real-world system components:

- **`/fast` endpoint** (baseline):
  - Low latency (typically < 10ms)
  - High throughput (hundreds or thousands of RPS)

- **`/memory` endpoint** (RAM-like):
  - Very low latency (~1ms)
  - Very high throughput (thousands of RPS)

- **`/database` endpoint** (HDD-like):
  - Medium latency (~20ms)
  - Medium throughput (hundreds of RPS)

- **`/slow` endpoint** (network-like):
  - High latency (≈1000ms due to artificial delay)
  - Much lower throughput (typically < 100 RPS)

### Analyzing the Results

The results demonstrate that:
1. **Latency directly impacts throughput**: The 2-second delay in the `/slow` endpoint drastically reduces throughput.
2. **Concurrency helps mitigate latency**: Even with high latency, increased concurrency can maintain throughput up to a point.

## Real-world Applications

Understanding the relationship between latency and throughput is crucial for:

1. **Backend Optimization**: Reducing database query times or API call latency to improve overall throughput
2. **Infrastructure Scaling**: Deciding between vertical scaling (faster machines) or horizontal scaling (more machines)
3. **Client-side Performance**: Implementing techniques like caching and lazy loading to improve UX

## License

ISC 

## Troubleshooting

### Common Issues and Solutions

#### 1. Nginx Configuration Not Being Used

**Problem**: Changes to `config/nginx.conf` not reflected when accessing the application.

**Solution**: Nginx might be using the default configuration file instead of your custom one. To fix this:

```bash
# Stop any running Nginx instance
sudo nginx -s stop

# Start Nginx with your custom configuration (use full path)
sudo nginx -c $(pwd)/config/nginx.conf
```

**Note**: If you see an error about missing `mime.types`, modify your `nginx.conf` to include the full path:

```
http {
    include       /etc/nginx/mime.types;  # Use absolute path instead of relative
    # rest of configuration...
}
```

#### 2. Headers Not Being Passed Through Nginx

**Problem**: Custom headers set in Nginx (`proxy_set_header`) not appearing in the Node.js application.

**Solution**: 
- Make sure header names are consistent between Nginx and your application code
- Headers in Express.js are case-insensitive and are converted to lowercase
- Use proper quoting for header values in Nginx: `proxy_set_header X-Header "value"`
- Add the `Host` header when proxying: `proxy_set_header Host $host;`

Example of correct configuration:

```
# In nginx.conf
proxy_set_header test-proxy-header "true";

# In server.js
const headerValue = req.headers["test-proxy-header"] || "Not set";
```

#### 3. Inconsistent Proxy Behavior

**Problem**: Different behavior when accessing the application through Nginx vs directly.

**Solution**:
- Ensure you're using the same proxy_pass URL style consistently
- When using upstream blocks, ensure they're properly configured
- Add standard proxy headers for better compatibility:

```
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

#### 4. Changes to Nginx Configuration Not Taking Effect

**Problem**: Modifications to the `config/nginx.conf` file don't seem to have any effect even after restarting services.

**Solution**: When using a custom Nginx configuration, you need to explicitly reload it from the correct path:

```bash
# First, stop any running Nginx instances
sudo nginx -s stop

# Then start Nginx with your custom configuration file using absolute path
sudo nginx -c $(pwd)/config/nginx.conf

# To check if your configuration is valid before applying
sudo nginx -t -c $(pwd)/config/nginx.conf
```

**Important**: Every time you modify your `nginx.conf` file, you need to reload the configuration with these commands for changes to take effect.

For convenience, we've created a helper script that does this for you:

```bash
# Make sure the script is executable
chmod +x scripts/restart-nginx.sh

# Run the script to restart Nginx with your custom configuration
./scripts/restart-nginx.sh
``` 