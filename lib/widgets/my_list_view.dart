// File: lib/list_row_model.dart
import 'package:flutter/material.dart';

// 給我一個Model 用於產生 ListView的row，這個Model包含一個checkbox的狀態、一個文字內容。這個Model應該有一個方法可以更新checkbox的狀態。
class ListRowModel {
  bool isChecked;
  String text;

  ListRowModel({required this.isChecked, required this.text});

  void toggleChecked() {
    isChecked = !isChecked;
  }
}

class ListRowController extends ChangeNotifier {
  List<ListRowModel> _models;

  ListRowController({required List<ListRowModel> initialModels})
      : _models = List.from(initialModels);

  List<ListRowModel> get value => _models;

  void add(ListRowModel newModel) {
    _models.add(newModel);
    notifyListeners();
  }

  void toggleAt(int index) {
    _models[index].toggleChecked();
    notifyListeners();
  }

  void removeAt(int index) {
    _models.removeAt(index);
    notifyListeners();
  }

  void set(List<ListRowModel> newList) {
    _models = List.from(newList);
    notifyListeners();
  }
}

/* 先幫我寫一個stateful widget 回傳一個ListView.builder的widget，這個widget會根據傳進來的
ListRowModels 回圈產生列表 row (checkbox + text + delete button)，
showCheckedRows 參數用來決定是否只顯示已勾選的row，
並且有一個可選onChanged的callback，當checkbox被點擊時會呼叫這個callback，並且傳回該更新狀態後的所有models。若沒有給 則一樣會更新 但是不呼叫callback。
onDelete的按鈕點擊時，會從列表中刪除該row，並且呼叫onChanged的callback，傳回更新後的models。
*/
class MyListView extends StatefulWidget {
  final ListRowController controller;
  final bool showCheckedRows;
  final Function()? onChanged;

  const MyListView({
    Key? key,
    required this.controller,
    this.showCheckedRows = false,
    this.onChanged,
  }) : super(key: key);

  @override
  _MyListViewState createState() => _MyListViewState();
}

class _MyListViewState extends State<MyListView> {

  @override
  Widget build(BuildContext context) {
    final visibleModels = widget.showCheckedRows
        ? widget.controller.value.where((model) => model.isChecked).toList()
        : widget.controller.value;

    return ListView.builder(
      itemCount: visibleModels.length,
      itemBuilder: (context, index) {
        final model = visibleModels[index];
        final realIndex = widget.controller.value.indexOf(model);
        return ListTile(
          key: ValueKey(model),
          leading: Checkbox(
            value: model.isChecked,
            onChanged: (value) {
              setState(() {
                widget.controller.toggleAt(realIndex);
                widget.onChanged?.call();
              });
            },
          ),
          title: Text(model.text),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                widget.controller.removeAt(realIndex);
                widget.onChanged?.call();
              });
            },
          ),
        );
      },
    );
  }
}