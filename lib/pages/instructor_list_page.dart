import 'package:flutter/material.dart';
import 'package:flutter_practice/widgets/expandable_item_card.dart';

/// 課程模型
class Course {
  final String id;
  final String title;
  final String time;

  Course({required this.id, required this.title, required this.time});
}

/// 講師模型，包含課程清單
class Instructor {
  final String id;
  final String name;
  final String title;
  final String imgUrl;
  final List<Course> courses;

  Instructor({
    required this.id,
    required this.name,
    required this.title,
    required this.imgUrl,
    required this.courses,
  });
}

/// 假資料：模擬後端回傳的 Instructor + 課程
final List<Instructor> mockInstructors = [
  Instructor(
    id: 'ins1',
    name: 'Albert Flores',
    title: 'Demonstrator',
    imgUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
    courses: [
      Course(id: 'c1', title: '基礎程式設計', time: '每週二, 10:00–12:00'),
      Course(id: 'c2', title: '人工智慧邏輯與實作', time: '每週四, 14:00–16:00'),
    ],
  ),
  Instructor(
    id: 'ins2',
    name: 'Floyd Miles',
    title: 'Lecturer',
    imgUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
    courses: [
      Course(id: 'c3', title: '資料庫系統概論', time: '每週一, 09:00–11:00'),
      Course(id: 'c4', title: '網頁前端開發', time: '每週三, 13:00–15:00'),
    ],
  ),
];

/// 將 Instructor 資料轉為 ItemModel（用於 ExpandableItemCard）
List<ExpandableTileModel> convertToItemModelList(List<Instructor> data) {
  return data.map((instructor) {
    final List<ExpandableTileModel> courseItems = instructor.courses.map((course) {
      return ExpandableTileModel(
        key: ValueKey(course.id),
        title: course.title,
        subtitle: course.time,
        leadingWidget: const Icon(Icons.calendar_today),
        trailingIcon: const Icon(Icons.chevron_right),
      );
    }).toList();

    return ExpandableTileModel(
      key: ValueKey(instructor.id),
      title: instructor.name,
      subtitle: instructor.title,
      leadingWidget: CircleAvatar(
        backgroundImage: NetworkImage(instructor.imgUrl),
      ),
      children: courseItems.isEmpty ? null : courseItems,
    );
  }).toList();
}

/// 顯示講師清單頁面
class InstructorListPage extends StatelessWidget {
  InstructorListPage({super.key});

  final List<ExpandableTileModel> instructors = convertToItemModelList(mockInstructors);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: instructors
          .map((instructor) => ExpandableItemCard(itemModel: instructor))
          .toList(),
    );
  }
}
