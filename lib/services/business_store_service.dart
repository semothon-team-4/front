class BusinessStoreService {
  static final List<Map<String, dynamic>> _businesses = [
    {
      'name': '크린토피아 홈플러스 영통점',
      'kakaoPlaceId': '163269301',
      'type': '세탁소',
      'rating': 3.0,
      'reviews': 32,
      'likes': 123,
      'isLiked': false,
      'isVerified': true,
      'distance': '350m',
      'distanceM': 350,
      'address': '경기 수원시 영통구 봉영로 1576',
      'tags': ['드라이클리닝', '운동화세탁'],
      'isOpen': true,
      'hours': '10:00 - 21:00',
      'lat': 37.2414807483987,
      'lng': 127.073526926382,
      'imagePath': null,
    },
    {
      'name': '화이트 365 수원 영통점',
      'kakaoPlaceId': '1630247871',
      'type': '세탁소',
      'rating': 4.0,
      'reviews': 51,
      'likes': 51,
      'isLiked': false,
      'isVerified': false,
      'distance': '420m',
      'distanceM': 420,
      'address': '경기 수원시 영통구 청명남로 39',
      'tags': ['24시간', '무인빨래방'],
      'isOpen': true,
      'hours': '24시간 영업, 무인 빨래방',
      'lat': 37.2406555567841,
      'lng': 127.073259023517,
      'imagePath': null,
    },
    {
      'name': '얼룩빼기이박사 박종술 명품 세탁',
      'kakaoPlaceId': '20034435',
      'type': '세탁소',
      'rating': 4.5,
      'reviews': 67,
      'likes': 254,
      'isLiked': false,
      'isVerified': true,
      'distance': '620m',
      'distanceM': 620,
      'address': '경기 수원시 영통구 반달로 7번길 16',
      'tags': ['명품세탁', '얼룩제거'],
      'isOpen': false,
      'hours': '영업 종료, 내일 휴무',
      'lat': 37.2403517002043,
      'lng': 127.072123835207,
      'imagePath': null,
    },
    {
      'name': '조은옷수선',
      'kakaoPlaceId': '25575688',
      'type': '수선집',
      'rating': 4.6,
      'reviews': 29,
      'likes': 74,
      'isLiked': false,
      'isVerified': false,
      'distance': '1.1km',
      'distanceM': 1100,
      'address': '경기 수원시 영통구 봉영로 1569',
      'tags': ['기장수선', '지퍼교체'],
      'isOpen': true,
      'hours': '10:00 - 19:00',
      'lat': 37.25206054677226,
      'lng': 127.07101232386925,
      'imagePath': null,
    },
  ];

  static List<Map<String, dynamic>> getBusinesses() {
    return _businesses.map((b) => Map<String, dynamic>.from(b)).toList();
  }

  static void toggleLike(String name) {
    final target = _businesses.firstWhere((b) => b['name'] == name);
    final liked = target['isLiked'] as bool;
    target['isLiked'] = !liked;
    target['likes'] = (target['likes'] as int) + (liked ? -1 : 1);
  }

  static List<Map<String, dynamic>> getLikedBusinesses() {
    return _businesses
        .where((b) => b['isLiked'] == true)
        .map((b) => Map<String, dynamic>.from(b))
        .toList();
  }

  static List<Map<String, dynamic>> getFavoriteBusinessesForUser(
    String userName,
  ) {
    final manualFavorites = <String, List<String>>{
      '세탁왕김씨': ['크린토피아 홈플러스 영통점', '화이트 365 수원 영통점'],
      '옷수선마스터': ['조은옷수선', '화이트 365 수원 영통점'],
      '깔끔생활': ['얼룩빼기이박사 박종술 명품 세탁'],
      '패션피플': ['화이트 365 수원 영통점'],
      '옷장관리자': ['크린토피아 홈플러스 영통점', '얼룩빼기이박사 박종술 명품 세탁'],
      '닉네임1': [],
    };

    final favoriteNames = manualFavorites[userName];
    if (favoriteNames == null || favoriteNames.isEmpty) {
      return getLikedBusinesses();
    }

    return _businesses
        .where((b) => favoriteNames.contains(b['name']))
        .map((b) => Map<String, dynamic>.from(b))
        .toList();
  }
}
