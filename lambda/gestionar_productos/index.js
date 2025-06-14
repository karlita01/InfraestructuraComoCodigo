// Logs en formato JSON para facilitar el análisis en index.js gestionar_productos

const { Client } = require("pg");

exports.handler = async (event) => {
  console.info(JSON.stringify({
    event: "evento_recibido",
    body: event.body,
    timestamp: new Date().toISOString()
  }));

  let body;
  try {
    body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch (parseError) {
    console.error(JSON.stringify({
      event: "error_parseo_body",
      error: parseError.message,
      timestamp: new Date().toISOString()
    }));
    return buildResponse(400, { error: "Body inválido. Debe ser JSON." });
  }

  const { id, nombre, descripcion, cantidad, habilitado } = body;

  if (!id || !nombre || cantidad == null || habilitado == null) {
    console.error(JSON.stringify({
      event: "error_validacion",
      error: "Faltan campos requeridos",
      body,
      timestamp: new Date().toISOString()
    }));
    return buildResponse(400, {
      error: "Faltan campos requeridos: id, nombre, cantidad, habilitado"
    });
  }

  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD
  });

  try {
    await client.connect();
    console.info(JSON.stringify({
      event: "conexion_db",
      status: "ok",
      timestamp: new Date().toISOString()
    }));

    const query = `
      INSERT INTO productos (id, nombre, descripcion, cantidad, habilitado)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (id) DO UPDATE SET
        nombre = EXCLUDED.nombre,
        descripcion = EXCLUDED.descripcion,
        cantidad = EXCLUDED.cantidad,
        habilitado = EXCLUDED.habilitado;
    `;
    const values = [id, nombre, descripcion, cantidad, habilitado];

    await client.query(query, values);

    console.info(JSON.stringify({
      event: "producto_creado",
      mensaje: `El producto ${nombre} fue creado`,
      nombre_producto: nombre,
      timestamp: new Date().toISOString()
    }));

    console.info(JSON.stringify({
      event: "producto_insertado_actualizado",
      values,
      habilitado,
      timestamp: new Date().toISOString()
    }));

    return buildResponse(200, {
      mensaje: habilitado
        ? `✅ Producto ${nombre} creado correctamente en PostgreSQL`
        : `🛑 Producto ${nombre} deshabilitado en PostgreSQL`
    });
  } catch (err) {
    console.error(JSON.stringify({
      event: "error_ejecucion",
      error: err.message,
      stack: err.stack,
      timestamp: new Date().toISOString()
    }));
    return buildResponse(500, {
      error: "Error al guardar en PostgreSQL: " + err.message
    });
  } finally {
    await client.end().catch((e) =>
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

function buildResponse(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    },
    body: JSON.stringify(body)
  };
}