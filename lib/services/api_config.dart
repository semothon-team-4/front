class ApiConfig {
  // 기본 서버: 신규 서버 IP
  // 필요하면 실행 시 --dart-define=API_BASE_URL=http://x.x.x.x:port 로 덮어쓸 수 있음
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://3.236.103.189:8080',
  );
}
