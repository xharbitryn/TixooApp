// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:tixxo/category/events.dart';
// import 'package:tixxo/widgets/divider.dart';

// class CategorySection extends StatelessWidget {
//   const CategorySection({super.key});

//   final List<Map<String, String>> categories = const [
//     {'image': 'magic.png', 'name': 'Magic'},
//     {'image': 'greet.png', 'name': 'Greet'},
//     {'image': 'workshop.png', 'name': 'Workshop'},
//     {'image': 'sports.png', 'name': 'Sports'},
//     {'image': 'Musicc.png', 'name': 'Music'},
//     {'image': 'comedy.png', 'name': 'Play'},
//     {'image': 'poetry.png', 'name': 'Poetry'},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Title with lines on both sides
//         const GradientDivider(title: "Featured Categories"),

//         const SizedBox(height: 10),

//         // Category list
//         SizedBox(
//           height: 90,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: categories.map((category) {
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) =>
//                             CategoryEventsPage(categoryName: category['name']!),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     width: 90,
//                     margin: const EdgeInsets.only(left: 16),

//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.all(8),
//                             child: Image.asset(
//                               'assets/images/${category['image']}',
//                               fit: BoxFit.contain,
//                             ),
//                           ),
//                         ),

//                         Text(
//                           category['name']!,
//                           style: GoogleFonts.poppins(
//                             color: Colors.white,
//                             fontSize: 12,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
