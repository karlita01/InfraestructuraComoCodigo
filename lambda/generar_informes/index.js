// Logs en formato JSON para facilitar el análisis en index.js generar_informes
const { Client } = require("pg");

exports.handler = async () => {
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
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

    const hoy = new Date();
    const hace30Dias = new Date(hoy);
    hace30Dias.setDate(hoy.getDate() - 30);

    const queryPedidos = `
      SELECT p.idpedido, p.fecha, pp.idproducto, pp.cantidad
      FROM pedido p
      JOIN pedido_producto pp ON p.idpedido = pp.idpedido
      WHERE p.fecha >= $1
    `;

    const res = await client.query(queryPedidos, [hace30Dias.toISOString()]);
    const pedidosUltimos30 = res.rows;

    const informe = {
      id: `informe_${new Date().toISOString()}`,
      fecha: new Date().toISOString(),
      pedidos: pedidosUltimos30
    };

    console.info(JSON.stringify({
      event: "informe_generado",
      cantidad_pedidos: pedidosUltimos30.length,
      fecha: informe.fecha,
      timestamp: new Date().toISOString()
    }));

    await client.end();
    console.info(JSON.stringify({
      event: "conexion_cerrada",
      timestamp: new Date().toISOString()
    }));

    return {
      statusCode: 200,
      body: JSON.stringify(informe) 
    };
  } catch (error) {
    console.error(JSON.stringify({
      event: "error_generar_informe",
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    }));
    await client.end().catch(e =>
      console.warn(JSON.stringify({
        event: "error_cerrando_conexion",
        error: e.message,
        timestamp: new Date().toISOString()
      }))
    );
    return {
      statusCode: 500,
      body: "Error al generar el informe"
    };
  }
};