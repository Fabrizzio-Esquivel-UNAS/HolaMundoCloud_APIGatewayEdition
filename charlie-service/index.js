const express = require('express');
const app = express();
const port = 3003;

app.get('/', (req, res) => {
    res.send('¡Hola desde Charlie!');
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
