const endpoint1 = "https://api.example.com/alpha"; // API Gateway path for EC2 instance 1
const endpoint2 = "https://api.example.com/charlie"; // API Gateway path for EC2 instance 2

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