// Logs en formato JSON para facilitar el análisis en index.js gestionar_pedidos
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
  } catch (err) {
    console.error(JSON.stringify({
      event: "error_parseo_body",
      error: err.message,
      timestamp: new Date().toISOString()
    }));
    return buildResponse(400, { error: "JSON inválido en el body" });
  }

  const { idpedido, productos, fecha } = body;

  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    await client.connect();
    console.info(JSON.stringify({
      event: "conexion_db",
      status: "ok",
      timestamp: new Date().toISOString()
    }));

    for (const p of productos) {
      const res = await client.query(
        "SELECT cantidad, habilitado FROM productos WHERE id = $1",
        [p.idproducto]
      );

      if (res.rows.length === 0 || !res.rows[0].habilitado || res.rows[0].cantidad < p.cantidad) {
        if (res.rows[0]?.cantidad === 0) {
          console.warn(JSON.stringify({
            event: "producto_sin_stock",
            producto: p.idproducto,
            mensaje: `El producto ${p.idproducto} se quedó sin stock. Enviando alerta`,
            timestamp: new Date().toISOString()
          }));
        } else {
          console.warn(JSON.stringify({
            event: "producto_no_disponible",
            producto: p.idproducto,
            cantidad_solicitada: p.cantidad,
            cantidad_disponible: res.rows[0]?.cantidad,
            habilitado: res.rows[0]?.habilitado,
            timestamp: new Date().toISOString()
          }));
        }
        return buildResponse(400, {
          error: `Producto ${p.idproducto} no disponible o stock insuficiente`
        });
      }
    }

    await client.query("BEGIN");

    await client.query(
      "INSERT INTO pedidos (idpedido, fecha) VALUES ($1, $2)",
      [idpedido, fecha]
    );

    for (const p of productos) {
      await client.query(
        "INSERT INTO pedido_productos (idpedido, idproducto, cantidad) VALUES ($1, $2, $3)",
        [idpedido, p.idproducto, p.cantidad]
      );

      await client.query(
        "UPDATE productos SET cantidad = cantidad - $1 WHERE id = $2",
        [p.cantidad, p.idproducto]
      );

      // Log solicitado: producto descontado
      console.info(JSON.stringify({
        event: "producto_descontado",
        mensaje: `Se ha descontado ${p.cantidad} ${p.idproducto}`,
        idproducto: p.idproducto,
        cantidad: p.cantidad,
        timestamp: new Date().toISOString()
      }));
    }

    await client.query("COMMIT");

    console.info(JSON.stringify({
      event: "pedido_registrado",
      idpedido,
      productos,
      timestamp: new Date().toISOString()
    }));

    return buildResponse(200, {
      mensaje: "🛒 Pedido registrado correctamente"
    });
  } catch (error) {
    console.error(JSON.stringify({
      event: "error_procesar_pedido",
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    }));

    await client.query("ROLLBACK");

    return buildResponse(500, {
      error: "Error al procesar el pedido: " + error.message
    });
  } finally {
    await client.end().catch(err =>
      console.warn(JSON.stringify({
        event: "error_cerrando_conexion",
        error: err.message,
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