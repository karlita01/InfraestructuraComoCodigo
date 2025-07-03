const AWS = require('aws-sdk');
const { Client } = require("pg");
const sns = new AWS.SNS();

exports.handler = async (event) => {
  let body;
  try {
    body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch (err) {
    return buildResponse(400, { error: "JSON inválido en el body" });
  }

  const { idproducto } = body || {};

  // Conexión a la base de datos
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    await client.connect();
    const res = await client.query(
      "SELECT cantidad FROM productos WHERE id = $1",
      [idproducto]
    );
    const cantidad = res.rows[0]?.cantidad ?? 0;

    if (cantidad <= 0) {
      // Publica alerta en SNS
      await sns.publish({
        TopicArn: process.env.SNS_TOPIC_ARN,
        Subject: "Alerta de Stock Vacío",
        Message: `El producto ${idproducto} está sin stock.`
      }).promise();
      return buildResponse(200, { alerta: "Stock vacío, alerta enviada" });
    }
    return buildResponse(200, { mensaje: "Stock suficiente" });
  } catch (err) {
    return buildResponse(500, { error: err.message });
  } finally {
    await client.end();
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