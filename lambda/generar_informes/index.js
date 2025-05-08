const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async () => {
  const hoy = new Date();
  const hace30Dias = new Date(hoy);
  hace30Dias.setDate(hoy.getDate() - 30);

  const todosPedidos = await dynamodb.scan({ TableName: process.env.PEDIDOS_TABLE }).promise();

  const pedidosUltimos30 = todosPedidos.Items.filter(p => {
    const fecha = new Date(p.fecha);
    return fecha >= hace30Dias;
  });

  const informe = {
    id: `informe_${new Date().toISOString()}`,
    fecha: new Date().toISOString(),
    pedidos: pedidosUltimos30
  };

  await dynamodb.put({
    TableName: process.env.INFORMES_TABLE,
    Item: informe
  }).promise();

  return {
    statusCode: 200,
    body: "📄 Se ha generado un informe de los últimos 30 días"
  };
};
