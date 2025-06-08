// Logs en formato JSON para facilitar el análisis en index.js init_db

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
    console.info(JSON.stringify({
      event: "conexion_db",
      status: "iniciando",
      timestamp: new Date().toISOString()
    }));
    await client.connect();
    console.info(JSON.stringify({
      event: "conexion_db",
      status: "ok",
      timestamp: new Date().toISOString()
    }));

    console.info(JSON.stringify({
      event: "creando_tabla",
      tabla: "productos",
      timestamp: new Date().toISOString()
    }));
    await client.query(`
      CREATE TABLE IF NOT EXISTS productos (
        id VARCHAR(255) PRIMARY KEY,
        nombre VARCHAR(255) NOT NULL,
        descripcion TEXT,
        cantidad INT NOT NULL,
        habilitado BOOLEAN NOT NULL
      );
    `);

    console.info(JSON.stringify({
      event: "creando_tabla",
      tabla: "pedidos",
      timestamp: new Date().toISOString()
    }));
    await client.query(`
      CREATE TABLE IF NOT EXISTS pedidos (
        idpedido VARCHAR(255) PRIMARY KEY,
        fecha TIMESTAMP NOT NULL
      );
    `);

    console.info(JSON.stringify({
      event: "creando_tabla",
      tabla: "pedido_productos",
      timestamp: new Date().toISOString()
    }));
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

    console.info(JSON.stringify({
      event: "tablas_creadas",
      status: "ok",
      timestamp: new Date().toISOString()
    }));
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Tablas creadas correctamente' }),
    };
  } catch (error) {
    console.error(JSON.stringify({
      event: "error_crear_tablas",
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    }));
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error al crear las tablas', error: error.message }),
    };
  } finally {
    await client.end().catch(e =>
      console.warn(JSON.stringify({
        event: "error_cerrando_conexion",
        error: e.message,
        timestamp: new Date().toISOString()
      }))
    );
    console.info(JSON.stringify({
      event: "conexion_cerrada",
      timestamp: new Date().toISOString()
    }));
  }
};