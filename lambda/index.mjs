import AWS from "aws-sdk";

const dynamodb = new AWS.DynamoDB.DocumentClient();

export const handler = async (event) => {
  const params = {
    TableName: process.env.TABLE_NAME,
    Item: {
      id: "1",
      nombre: "Producto demo",
      precio: 10.5
    }
  };

  try {
    await dynamodb.put(params).promise();
    return {
      statusCode: 200,
      body: "Producto guardado en DynamoDB"
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: "Error al guardar: " + err
    };
  }
};
