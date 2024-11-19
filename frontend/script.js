const endpoint1 = "https://rvth3ucrcg.execute-api.us-east-2.amazonaws.com/stage/instance1"; // API Gateway path for EC2 instance 1
const endpoint2 = "https://rvth3ucrcg.execute-api.us-east-2.amazonaws.com/stage/instance2"; // API Gateway path for EC2 instance 2

// Function to measure the response time and display the message
async function measureTime(endpoint, resultElementId, responseElementId) {
    const startTime = performance.now();
    try {
        const response = await fetch(endpoint);
        const message = await response.text(); // Get the response text
        if (response.ok) {
            const endTime = performance.now();
            const duration = Math.round(endTime - startTime); // Time in ms
            document.getElementById(resultElementId).innerText = `Response time: ${duration} ms`;
            document.getElementById(responseElementId).innerText = `Message: "${message}"`;
        } else {
            document.getElementById(resultElementId).innerText = `Failed with status: ${response.status}`;
            document.getElementById(responseElementId).innerText = `Message: "${message}"`;
        }
    } catch (error) {
        document.getElementById(resultElementId).innerText = `Error: ${error.message}`;
        document.getElementById(responseElementId).innerText = `Message: Unable to fetch response.`;
    }
}

// Event listeners for buttons
document.getElementById("endpoint1-btn").addEventListener("click", () => {
    measureTime(endpoint1, "result1", "response1");
});

document.getElementById("endpoint2-btn").addEventListener("click", () => {
    measureTime(endpoint2, "result2", "response2");
});

// Fibonacci API interaction
const fibonacciForm = document.getElementById('fibonacci-form');
const fibResultDiv = document.getElementById('fibonacci-results');

// Listen to Fibonacci form submit
fibonacciForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const count = document.getElementById('fibonacci-count').value;
  const times = document.getElementById('fibonacci-times').value;

  if (count && times) {
    fibResultDiv.innerHTML = 'Calculating...';
    const results = await makeFibonacciCalls(count, times);
    fibResultDiv.innerHTML = '';
    results.forEach((result, index) => {
      const p = document.createElement('p');
      p.textContent = `Call ${index + 1}: Fibonacci(${count}) = ${result}`;
      fibResultDiv.appendChild(p);
    });
  }
});

// Make multiple asynchronous Fibonacci API calls
async function makeFibonacciCalls(count, times) {
  const promises = [];
  for (let i = 0; i < times; i++) {
    promises.push(fetch(endpoint1+`/fibonacci/${count}`).then(res => res.json()));
    promises.push(fetch(endpoint2+`/fibonacci/${count}`).then(res => res.json()));
  }

  const results = await Promise.all(promises);
  return results.map(result => result.result);
}