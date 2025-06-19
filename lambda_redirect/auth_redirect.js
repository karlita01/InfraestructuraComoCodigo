'use strict';

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  const host = headers.host[0].value;
  const uri = request.uri;

  // 1. Obtener cookies del request
  let cookies = "";
  if (headers.cookie) {
    cookies = headers.cookie.map(c => c.value).join("; ");
  }

  // 2. Permitir acceso solo si ya tiene id_token
  // NUEVO: Si la URL contiene el fragmento #id_token, dejarlo pasar
  if (cookies.includes("id_token=") || uri.includes("#id_token")) {
  return request;
}

  // 3. Evitar loop infinito de redirección
  const redirectUrl = "https://" + host + uri;
  if (redirectUrl.includes("amazoncognito.com") || uri.startsWith("/login")) {
    return request;
  }

  // 4. Redirigir a Cognito
  const cognito_domain = "https://minimarkets-dc101127.auth.us-east-1.amazoncognito.com";
  const client_id = "5os4a5vtq0epf82r1oifggujk2";
  const login_url = `https://minimarkets-dc101127.auth.us-east-1.amazoncognito.com/login?response_type=token&client_id=5os4a5vtq0epf82r1oifggujk2&redirect_uri=` + encodeURIComponent(redirectUrl);

  return {
    status: '302',
    statusDescription: 'Found',
    headers: {
      location: [{ key: 'Location', value: login_url }]
    }
  };
};