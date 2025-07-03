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

  const { username, password } = body || {};

  // Lógica de autenticación simple (reemplaza por la real)
  if (username === "admin" && password === "admin") {
    console.info(JSON.stringify({
      event: "login_exitoso",
      username,
      timestamp: new Date().toISOString()
    }));
    return buildResponse(200, { mensaje: "Login exitoso" });
  } else {
    console.warn(JSON.stringify({
      event: "login_fallido",
      username,
      timestamp: new Date().toISOString()
    }));
    return buildResponse(401, { mensaje: "Credenciales inválidas" });
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