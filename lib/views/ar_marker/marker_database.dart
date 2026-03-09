/// MarkerDatabase – maps ArUco Marker IDs to application data.
/// Replace or extend this with your actual data source (REST API, SQLite, etc.)

class MarkerInfo {
  final int id;
  final String name;
  final String category;
  final String description;
  final Map<String, dynamic> additionalData;

  const MarkerInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.additionalData = const {},
  });
}

class MarkerDatabase {
  // ── Static local mapping (replace with DB/API call as needed) ──
  static final Map<int, MarkerInfo> _localData = {
    0: MarkerInfo(
      id: 0,
      name: 'สินค้า A-001',
      category: 'คลังสินค้า',
      description: 'กล่องสินค้าชั้น A ช่องที่ 1',
      additionalData: {'จำนวน': 50, 'หน่วย': 'ชิ้น', 'สถานะ': 'พร้อมจ่าย'},
    ),
    1: MarkerInfo(
      id: 1,
      name: 'ห้องประชุม B',
      category: 'สถานที่',
      description: 'ห้องประชุมชั้น 3 อาคาร B',
      additionalData: {'ความจุ': '20 คน', 'อุปกรณ์': 'โปรเจกเตอร์, ไวท์บอร์ด'},
    ),
    2: MarkerInfo(
      id: 2,
      name: 'เครื่องจักร CNC-02',
      category: 'เครื่องจักร',
      description: 'เครื่อง CNC หมายเลข 2 โซนการผลิต',
      additionalData: {
        'รุ่น': 'Fanuc 0i-F',
        'บำรุงรักษาล่าสุด': '2025-01-15',
        'สถานะ': 'ปกติ',
      },
    ),
    3: MarkerInfo(
      id: 3,
      name: 'Asset IT-003',
      category: 'ครุภัณฑ์',
      description: 'คอมพิวเตอร์ตั้งโต๊ะ ฝ่าย IT',
      additionalData: {
        'Serial': 'SN-20240301-003',
        'ผู้รับผิดชอบ': 'สมชาย ใจดี',
        'ซื้อเมื่อ': '2024-03-01',
      },
    ),
  };

  /// Get marker info from local map.
  /// TODO: Replace with async DB/API call for production.
  MarkerInfo? getMarkerInfo(int id) {
    return _localData[id];
  }

/// Example: fetch from REST API
/// Future<MarkerInfo?> fetchFromApi(int id) async {
///   final res = await http.get(Uri.parse('https://your-api.com/markers/$id'));
///   if (res.statusCode == 200) {
///     return MarkerInfo.fromJson(jsonDecode(res.body));
///   }
///   return null;
/// }
}