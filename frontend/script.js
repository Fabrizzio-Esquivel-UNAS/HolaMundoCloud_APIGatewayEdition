document.getElementById("fetch-data").addEventListener("click", async () => {
    const responseContainer = document.getElementById("response");
    try {
        const response = await fetch("https://st56qzz7dk.execute-api.us-east-2.amazonaws.com/cloud");
        const data = await response.json();
        responseContainer.textContent = data.message;
    } catch (error) {
        responseContainer.textContent = "Error fetching data";
    }
});