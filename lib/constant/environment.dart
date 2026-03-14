enum Environment {
  development,
  production,
}

String getBaseURL() {
  String baseURL;
  Environment env = Environment.production;

  switch (env) {
    case Environment.production:
      // baseURL = 'http://192.168.1.36:3000';
      baseURL = 'http://172.20.10.5:3000';
      break;

    default:
      baseURL = 'http://localhost:3000';
  }

  return baseURL;
}
