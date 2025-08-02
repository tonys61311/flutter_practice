import 'package:flutter/material.dart';

/// 資料模型：用來描述每一個可展開項目的內容與樣式
class ExpandableTileModel {
  final String title; // 必填標題
  final String? subtitle; // 副標題
  final TextStyle? titleStyle; // 標題樣式
  final TextStyle? subtitleStyle; // 副標題樣式
  final double? width; // 指定卡片寬度
  final double? height; // 指定卡片高度
  final EdgeInsetsGeometry? padding; // 外圍 padding
  final Widget? leadingWidget; // 開頭的圖示/圖片 widget（例如 icon/avatar）
  final Icon? trailingIcon; // 若無子項目可自定義右側 icon
  final VoidCallback? onTrailingPressed; // 點擊右側 icon 的處理函式
  final List<ExpandableTileModel>? children; // 子項目（遞迴呼叫自己）
  final Key? key; // Flutter widget identity key

  ExpandableTileModel({
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.width,
    this.height,
    this.padding,
    this.leadingWidget,
    this.trailingIcon,
    this.onTrailingPressed,
    this.children,
    this.key,
  });
}

/// 可展開的卡片元件，支援巢狀結構顯示
class ExpandableItemCard extends StatefulWidget {
  final ExpandableTileModel itemModel; // 當前要顯示的項目
  final bool wrapWithCard; // 是否將內容包在 Card 小卡片內（預設 true）

  ExpandableItemCard({
    required this.itemModel,
    this.wrapWithCard = true,
  }) : super(key: itemModel.key); // 直接使用 itemModel 的 key 給父類別

  @override
  State<ExpandableItemCard> createState() => _ExpandableItemCardState();
}

class _ExpandableItemCardState extends State<ExpandableItemCard> {
  bool _expanded = false; // 控制是否展開子項目

  /// 處理 leading widget（開頭圖示或圖片），並加右側 padding
  Widget? _buildLeadingWidget() {
    final leading = widget.itemModel.leadingWidget;
    if (leading == null) return null;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: leading,
    );
  }

  /// 處理 trailing widget：
  /// - 若有子項目，顯示展開 / 收合按鈕
  /// - 若無子項目，但有 trailingIcon，則顯示自定義按鈕
  Widget? _buildTrailingWidget() {
    final item = widget.itemModel;
    if (item.children != null) {
      return IconButton(
        icon: Icon(_expanded ? Icons.remove : Icons.add),
        onPressed: () => setState(() => _expanded = !_expanded),
      );
    } else if (item.trailingIcon != null) {
      return IconButton(
        icon: item.trailingIcon!,
        onPressed: item.onTrailingPressed,
      );
    }
    return null;
  }

  /// 處理展開時的子項目列表
  /// 若未展開或無子項目，回傳空清單
  List<Widget> _buildChildWidgets() {
    final children = widget.itemModel.children;
    if (children == null || !_expanded) return [];

    return [
      // 子項目展開時，上方顯示分隔線
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Divider(height: 1),
      ),
      // 遞迴渲染子項目 ExpandableItemCard
      ...children.map((child) => ExpandableItemCard(
        itemModel: child,
        wrapWithCard: false, // 子項目不包 Card
      )),
    ];
  }

  /// 組裝內容區塊（leading、標題、副標題、trailing、子項目）
  Widget _buildContent(Widget? leading, Widget? trailing, List<Widget> children) {
    final item = widget.itemModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: item.padding ?? const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) leading,
              // 標題與副標題（撐滿可用空間）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: item.subtitleStyle ?? const TextStyle(color: Colors.grey),
                      ),
                    Text(
                      item.title,
                      style: item.titleStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        // 展開時的子項目
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 預先建構好各個部分，保持 build() 簡潔
    final leadingWidget = _buildLeadingWidget();
    final trailingWidget = _buildTrailingWidget();
    final childWidgets = _buildChildWidgets();

    final content = _buildContent(leadingWidget, trailingWidget, childWidgets);

    // 根據 wrapWithCard 控制是否包在 Card 中
    return SizedBox(
      width: widget.itemModel.width,
      height: widget.itemModel.height,
      child: widget.wrapWithCard
          ? Card(child: content)
          : content,
    );
  }
}
