import { createServer } from 'http';

const instanceIndex = process.env.CF_INSTANCE_INDEX;

// CPU-intensive Fibonacci calculation
function fib(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}

const server = createServer((req, res) => {
  if (req.url == '/livez' || req.url == '/readyz') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('OK\n');
    return;
  }

  // Do CPU-intensive work
  const fibResult = fib(40);
  console.log(`Computed Fibonacci(40): ${fibResult}`);
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end(`Hello World! (CF_INSTANCE_INDEX: ${instanceIndex})\nFibonacci(40): ${fibResult}\n`);
});

// log when SIGTERM is received
process.once('SIGTERM', () => {
  console.log(`SIGTERM received`);
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

const port = process.env.PORT;
server.listen(port, "0.0.0.0", () => {
  console.log(`Server running at http://0.0.0.0:${port}/`);
});
