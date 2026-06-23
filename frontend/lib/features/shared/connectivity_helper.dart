import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

// const cacheKey = 'coach_profile';

//   final online = await ConnectivityHelper.isOnline();

//   if (!online) {
//     // Load from cache
//     final cached = await CacheService.load(cacheKey);
//     if (cached != null) {
//       return CoachProfileModel.fromJson(jsonDecode(cached));
//     }
//     throw Exception('No internet and no cached data available');
//   }



// // Add this to any screen's build method

// FutureBuilder<bool>(
//   future: ConnectivityHelper.isOnline(),
//   builder: (context, snapshot) {
//     if (snapshot.data == false) {
//       return Container(
//         width: double.infinity,
//         color: Colors.orange,
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: const Center(
//           child: Text(
//             'You are offline — showing cached data',
//             style: TextStyle(color: Colors.white, fontSize: 12),
//           ),
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   },
// ),