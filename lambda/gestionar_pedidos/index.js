const { Client } = require("pg");

exports.handler = async (event) => {
  console.log("Lambda gestionar_pedidos invocada");

  let body;
  try {
    body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch (err) {
    console.error("❌ Error al parsear body:", err);
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

    for (const p of productos) {
      const res = await client.query(
        "SELECT cantidad, habilitado FROM productos WHERE id = $1",
        [p.idproducto]
      );

      if (res.rows.length === 0 || !res.rows[0].habilitado || res.rows[0].cantidad < p.cantidad) {
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
    }

    await client.query("COMMIT");

    return buildResponse(200, {
      mensaje: "🛒 Pedido registrado correctamente"
    });
  } catch (error) {
    console.error("❌ Error al procesar el pedido:", error);

    await client.query("ROLLBACK");

    return buildResponse(500, {
      error: "Error al procesar el pedido: " + error.message
    });
  } finally {
    await client.end().catch(err =>
      console.warn("⚠️ Error cerrando la conexión:", err)
    );
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
