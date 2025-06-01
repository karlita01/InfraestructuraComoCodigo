const { Client } = require("pg");

exports.handler = async () => {
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD
  });

  await client.connect();

  const hoy = new Date();
  const hace30Dias = new Date(hoy);
  hace30Dias.setDate(hoy.getDate() - 30);

  const queryPedidos = `
    SELECT p.idpedido, p.fecha, pp.idproducto, pp.cantidad
    FROM pedido p
    JOIN pedido_producto pp ON p.idpedido = pp.idpedido
    WHERE p.fecha >= $1
  `;

  try {
    const res = await client.query(queryPedidos, [hace30Dias.toISOString()]);
    const pedidosUltimos30 = res.rows;

    const informe = {
      id: `informe_${new Date().toISOString()}`,
      fecha: new Date().toISOString(),
      pedidos: pedidosUltimos30
    };

    await client.end();

    return {
      statusCode: 200,
      body: JSON.stringify(informe) 
    };
  } catch (error) {
    console.error("Error al consultar la base de datos:", error);
    await client.end();
    return {
      statusCode: 500,
      body: "Error al generar el informe"
    };
  }
};
