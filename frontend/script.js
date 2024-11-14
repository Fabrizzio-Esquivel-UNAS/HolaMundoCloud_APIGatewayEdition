document.getElementById("fetch-data").addEventListener("click", async () => {
    const responseContainer = document.getElementById("response");
    try {
        const response = await fetch("https://YOUR_API_GATEWAY_URL/prod");
        const data = await response.json();
        responseContainer.textContent = data.message;
    } catch (error) {
        responseContainer.textContent = "Error fetching data";
    }
});
