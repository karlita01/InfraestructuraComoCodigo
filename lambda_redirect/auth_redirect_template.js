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
  const cognito_domain = "${cognito_domain}";
  const client_id = "${client_id}";
  const login_url = `${cognito_domain}/login?response_type=token&client_id=${client_id}&redirect_uri=` + encodeURIComponent(redirectUrl);

  return {
    status: '302',
    statusDescription: 'Found',
    headers: {
      location: [{ key: 'Location', value: login_url }]
    }
  };
};