document.getElementById("fetch-data").addEventListener("click", async () => {
    const responseContainer = document.getElementById("response");
    try {
        const response = await fetch("https://arn:aws:execute-api:us-east-2:676206932076:st56qzz7dk/*/*/{proxy+}/cloud");
        const data = await response.json();
        responseContainer.textContent = data.message;
    } catch (error) {
        responseContainer.textContent = "Error fetching data";
    }
});
