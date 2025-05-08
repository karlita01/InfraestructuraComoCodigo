const { Client } = require("pg");

exports.handler = async (event) => {
  console.log("📦 Evento recibido:", JSON.stringify(event));

  let body;
  try {
    body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch (parseError) {
    console.error("❌ Error parseando el body:", parseError);
    return buildResponse(400, { error: "Body inválido. Debe ser JSON." });
  }

  const { id, nombre, descripcion, cantidad, habilitado } = body;

  // Validación mínima
  if (!id || !nombre || cantidad == null || habilitado == null) {
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
    console.log("✅ Conexión a la base de datos exitosa");

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
    console.log("✅ Producto insertado/actualizado:", values);

    return buildResponse(200, {
      mensaje: habilitado
        ? `✅ Producto ${nombre} creado correctamente en PostgreSQL`
        : `🛑 Producto ${nombre} deshabilitado en PostgreSQL`
    });
  } catch (err) {
    console.error("❌ Error en la ejecución:", err);
    return buildResponse(500, {
      error: "Error al guardar en PostgreSQL: " + err.message
    });
  } finally {
    await client.end().catch((e) =>
      console.warn("⚠️ Error cerrando conexión:", e)
    );
    console.log("🔌 Conexión cerrada");
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