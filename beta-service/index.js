const express = require('express');
const app = express();
const port = 3001;

app.get('/', (req, res) => {
    res.send('¡Hola desde Beta!');
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
