class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://expense-backend-sigma-three.vercel.app',
  );
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '528416899893-3mqrmp86f1a3fkkib09rspd61ror73d6.apps.googleusercontent.com',
  );
}
