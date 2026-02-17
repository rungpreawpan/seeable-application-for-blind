enum Environment {
  development,
  production,
}

String getBaseURL() {
  String baseURL;
  Environment env = Environment.production;

  switch (env) {
    case Environment.production:
      // baseURL = 'http://100.121.10.234:3000';
      baseURL = 'http://192.168.1.35:3000';
      // baseURL = 'http://172.20.10.5:3000';
      //   baseURL = 'http://localhost:3000';
      // baseURL = 'http://172.17.26.228:3000';
      break;

    default:
      baseURL = 'http://localhost:3000';
  }

  return baseURL;
}
