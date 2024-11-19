const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();
const port = 3000;

// Use the CORS middleware
app.use(cors());

// Replace with your actual target endpoint
const targetEndpoint = 'http://localhost:443';

app.get('/', async (req, res) => {
    let targetResponseTime = 0;
    try {
        const responseStartTime = Date.now();
        const response = await axios.get(targetEndpoint); // Make a request to the other endpoint
        targetResponseTime = Date.now() - responseStartTime; // Calculate response time
    } catch (error) {
        console.error('Error calling Beta endpoint:', error.message);
    }

    res.send(`Beta Response Time: ${targetResponseTime}ms`);
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});

// Fibonacci Function
function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// New Fibonacci endpoint
app.get('/fibonacci/:num', (req, res) => {
    const num = parseInt(req.params.num);
    if (isNaN(num) || num < 0) {
        return res.status(400).json({ error: 'Invalid number' });
    }
    const result = fibonacci(num);
    res.json({ result });
});