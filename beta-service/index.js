const express = require('express');
const cors = require('cors');
const app = express();
const port = 3001;

// Use the CORS middleware
app.use(cors());

app.get('/', (req, res) => {
    res.send('¡Hola desde Beta!');
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
