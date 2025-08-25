const express = require("express");
const morgan = require("morgan");
const crypto = require("crypto");

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Custom logging middleware to track response times
app.use((req, res, next) => {
  // Generate truly unique ID for each request using UUID-like approach
  const requestId = crypto.randomUUID();
  const requestLabel = `Request ${requestId} - ${req.method} ${req.url}`;

  console.time(requestLabel);

  // Once the response is finished, log the time
  res.on("finish", () => {
    console.timeEnd(requestLabel);
  });

  next();
});

// Standard HTTP request logging
app.use(morgan("dev"));

// Routes
app.get("/", (req, res) => {
  const testHeader = req.headers["test-proxy-header"] || "Not set";
  res.status(200).send(`Hello World - Proxy Header: ${testHeader} \n`);
});

app.get("/fast", (req, res) => {
  res.status(200).send('Fast response \n');
});

app.get("/slow", (req, res) => {
  // Simulate a slow operation that takes 1 seconds
  setTimeout(() => {
    res.status(200).send('Slow response (after 1 second delay) \n');
  }, 1000);
});

// New endpoint to demonstrate different latency orders of magnitude
app.get("/database", (req, res) => {
  // Simulate database query latency (20ms - similar to HDD read)
  setTimeout(() => {
    res.status(200).send('Database response (20ms latency - HDD-like) \n');
  }, 20);
});

app.get("/memory", (req, res) => {
  // Simulate memory access latency (1ms - similar to RAM read)
  setTimeout(() => {
    res.status(200).send('Memory response (1ms latency - RAM-like) \n');
  }, 1);
});

// Health check endpoint
app.get("/health", (req, res) => {
  console.log("All headers:", req.headers);
  
  // Simplemente verificamos si el tráfico pasó por Nginx
  const viaNginx = req.headers["x-via-nginx"] ? true : false;
  
  res.status(200).send(`OK - Via Nginx: ${viaNginx} \n`);
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`- Fast endpoint: http://localhost:${PORT}/fast`);
  console.log(`- Slow endpoint: http://localhost:${PORT}/slow`);
});

module.exports = app;
