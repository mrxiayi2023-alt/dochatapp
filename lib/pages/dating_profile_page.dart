import 'package:flutter/cupertino.dart';
import 'dating_page.dart';

class DatingProfilePage extends StatelessWidget {
  final DatingUser user;
  const DatingProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatarSection(),
              _buildInfoCard(),
              _buildIntroCard(),
              const SizedBox(height: 20),
              _buildSendMessageButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: user.color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user.initial,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 36, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${user.age}岁', style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
            const Text(' · ', style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
            Text('${user.distance}km', style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.star_fill, size: 18, color: CupertinoColors.systemOrange),
            const SizedBox(width: 4),
            Text(
              '恋爱分数 ${user.score}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人标签', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: user.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(tag, style: TextStyle(fontSize: 14, color: user.color, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人介绍', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            user.intro,
            style: const TextStyle(fontSize: 15, color: CupertinoColors.black, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSendMessageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('发送消息'),
                content: Text('即将与${user.name}发起聊天'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('确定'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            );
          },
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          color: CupertinoColors.activeBlue,
          pressedOpacity: 0.7,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.chat_bubble_fill, size: 18, color: CupertinoColors.white),
              SizedBox(width: 6),
              Text('发送消息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
