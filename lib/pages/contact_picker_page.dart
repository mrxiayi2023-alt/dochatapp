// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：联系人选择页面

import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Contact model
// ---------------------------------------------------------------------------

class ContactItem {
  final String name;
  final String phone;
  final String avatarChar;

  const ContactItem({
    required this.name,
    required this.phone,
    required this.avatarChar,
  });
}

// ---------------------------------------------------------------------------
// Demo contacts
// ---------------------------------------------------------------------------

const List<ContactItem> _demoContacts = [
  ContactItem(name: '张三', phone: '13800001001', avatarChar: '张'),
  ContactItem(name: '李四', phone: '13800001002', avatarChar: '李'),
  ContactItem(name: '王五', phone: '13800001003', avatarChar: '王'),
  ContactItem(name: '赵六', phone: '13800001004', avatarChar: '赵'),
  ContactItem(name: '孙七', phone: '13800001005', avatarChar: '孙'),
  ContactItem(name: '周八', phone: '13800001006', avatarChar: '周'),
  ContactItem(name: '吴九', phone: '13800001007', avatarChar: '吴'),
  ContactItem(name: '郑十', phone: '13800001008', avatarChar: '郑'),
  ContactItem(name: '测试账号A', phone: '13900001001', avatarChar: 'A'),
  ContactItem(name: '测试账号B', phone: '13900001002', avatarChar: 'B'),
  ContactItem(name: '测试账号C', phone: '13900001003', avatarChar: 'C'),
  ContactItem(name: '测试账号D', phone: '13900001004', avatarChar: 'D'),
];

final List<Color> _avatarColors = [
  CupertinoColors.systemBlue,
  CupertinoColors.systemGreen,
  CupertinoColors.systemOrange,
  CupertinoColors.systemPurple,
  CupertinoColors.systemPink,
  CupertinoColors.systemTeal,
  CupertinoColors.systemRed,
  CupertinoColors.systemYellow,
];

Color _nameToColor(String name) {
  return _avatarColors[name.hashCode.abs() % _avatarColors.length];
}

// ---------------------------------------------------------------------------
// Contact Picker Page
// ---------------------------------------------------------------------------

class ContactPickerPage extends StatefulWidget {
  const ContactPickerPage({super.key});

  @override
  State<ContactPickerPage> createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {
  final _searchController = TextEditingController();
  String _query = '';

  List<ContactItem> get _filtered {
    if (_query.isEmpty) return _demoContacts;
    return _demoContacts
        .where((c) => c.name.contains(_query) || c.phone.contains(_query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectContact(ContactItem contact) {
    Navigator.of(context).pop({
      'name': contact.name,
      'phone': contact.phone,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('选择对方', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.5,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(fontSize: 17)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '搜索好友',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('未找到匹配的联系人',
                          style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => Container(
                        height: 0.5,
                        margin: const EdgeInsets.only(left: 68),
                        color: CupertinoColors.systemGrey5,
                      ),
                      itemBuilder: (_, i) {
                        final contact = _filtered[i];
                        return _buildContactRow(contact);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(ContactItem contact) {
    return GestureDetector(
      onTap: () => _selectContact(contact),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _nameToColor(contact.name),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                contact.avatarChar,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(contact.phone,
                      style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }
}
