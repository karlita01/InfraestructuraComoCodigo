const { Client } = require('pg');

exports.handler = async () => {
  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    console.log("Conectando a PostgreSQL...");
    await client.connect();

    console.log("Creando tabla productos...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS productos (
        id VARCHAR(255) PRIMARY KEY,
        nombre VARCHAR(255) NOT NULL,
        descripcion TEXT,
        cantidad INT NOT NULL,
        habilitado BOOLEAN NOT NULL
      );
    `);

    console.log("Creando tabla pedidos...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS pedidos (
        idpedido VARCHAR(255) PRIMARY KEY,
        fecha TIMESTAMP NOT NULL
      );
    `);

    console.log("Creando tabla pedido_productos...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS pedido_productos (
        idpedido VARCHAR(255) NOT NULL,
        idproducto VARCHAR(255) NOT NULL,
        cantidad INT NOT NULL,
        PRIMARY KEY (idpedido, idproducto),
        FOREIGN KEY (idpedido) REFERENCES pedidos(idpedido) ON DELETE CASCADE,
        FOREIGN KEY (idproducto) REFERENCES productos(id)
      );
    `);

    console.log("Tablas creadas correctamente");
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Tablas creadas correctamente' }),
    };
  } catch (error) {
    console.error('Error al crear las tablas:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error al crear las tablas', error: error.message }),
    };
  } finally {
    await client.end().catch(e =>
      console.warn("Error al cerrar la conexión:", e)
    );
    console.log("Conexión cerrada");
  }
};