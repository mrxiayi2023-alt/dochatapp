import 'dart:math';
import 'package:flutter/cupertino.dart';

class MallDisputePage extends StatefulWidget {
  const MallDisputePage({super.key});
  @override
  State<MallDisputePage> createState() => _MallDisputePageState();
}

class _MallDisputePageState extends State<MallDisputePage> {
  bool _isArbitrating = false;
  bool _hasApplied = false;
  bool? _won;
  int? _myVotes;
  int? _opponentVotes;
  String _evidenceType = '聊天记录';
  final _notesController = TextEditingController();
  final _evidenceNoteController = TextEditingController();
  bool _evidenceSubmitted = false;

  @override
  void dispose() {
    _notesController.dispose();
    _evidenceNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('众裁庭'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRulesCard(),
              const SizedBox(height: 16),
              if (!_hasApplied) _buildApplyButton(),
              if (_hasApplied && !_isArbitrating && _won == null)
                _buildEvidenceSection(),
              if (_isArbitrating) _buildArbitratingCard(),
              if (_won != null) _buildResultCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.shield_fill, size: 22, color: CupertinoColors.systemOrange),
              SizedBox(width: 8),
              Text('众裁规则', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. 系统将从信誉分 ≥ 85 的用户中随机邀请 17 位组成众裁团。\n'
            '2. 双方需提交聊天记录、图片、视频等凭证及补充说明。\n'
            '3. 众裁员独立审查证据并投票，先获得 9 票的一方胜诉。\n'
            '4. 裁决结果具有平台约束力，双方须遵守执行。',
            style: TextStyle(fontSize: 14, color: CupertinoColors.darkBackgroundGray, height: 1.7),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.info_circle, size: 16, color: CupertinoColors.systemOrange),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '温馨提示：虚假申请将扣除信誉分，严重者冻结账号。',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.systemOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return CupertinoButton(
      onPressed: () {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('申请仲裁'),
            content: const Text(
              '确认提交仲裁申请？\n\n'
              '提交后将进入证据收集阶段，请准备好相关凭证材料。',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('取消'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _hasApplied = true);
                },
                child: const Text('确认申请'),
              ),
            ],
          ),
        );
      },
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      color: CupertinoColors.systemOrange,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.shield_fill, size: 20, color: CupertinoColors.white),
          SizedBox(width: 8),
          Text('申请仲裁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    final evidenceTypes = ['聊天记录', '图片', '视频', '文件'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.doc_text, size: 20, color: CupertinoColors.activeBlue),
              SizedBox(width: 8),
              Text('提交证据', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('证据类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: evidenceTypes.map((type) {
              final selected = _evidenceType == type;
              return GestureDetector(
                onTap: () => setState(() => _evidenceType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected ? CupertinoColors.white : CupertinoColors.darkBackgroundGray,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('补充说明', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _evidenceNoteController,
            placeholder: '详细描述争议情况与诉求...',
            maxLines: 4,
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 16),
          if (!_evidenceSubmitted)
            CupertinoButton(
              onPressed: _evidenceNoteController.text.trim().isNotEmpty ? () {
                setState(() => _evidenceSubmitted = true);
                _showEvidenceSubmittedDialog();
              } : null,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: CupertinoColors.activeBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text('提交证据', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.checkmark_alt_circle, size: 18, color: CupertinoColors.systemGreen),
                  SizedBox(width: 6),
                  Text('证据已提交', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemGreen)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_evidenceSubmitted)
            CupertinoButton(
              onPressed: _startArbitration,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.systemOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.shield_fill, size: 20, color: CupertinoColors.white),
                  SizedBox(width: 8),
                  Text('发起众裁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showEvidenceSubmittedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('证据提交成功'),
        content: const Text('您的证据已成功提交，对方也将收到通知并提交证据。\n\n双方证据齐全后请点击"发起众裁"开始裁决。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildArbitratingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('众裁进行中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const CupertinoActivityIndicator(radius: 24),
          const SizedBox(height: 20),
          const Text(
            '17 位众裁员正在审查证据并投票...\n先获得 9 票的一方胜诉',
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('预计还需约 5 秒', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isWin = _won!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWin ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isWin ? CupertinoIcons.checkmark_alt_circle : CupertinoIcons.xmark_circle,
            size: 56,
            color: isWin ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed,
          ),
          const SizedBox(height: 12),
          Text(
            isWin ? '仲裁胜诉' : '仲裁败诉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isWin ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '你获得 $_myVotes 票 vs 对方 $_opponentVotes 票',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isWin
                ? '众裁团判定你方胜诉，对方须按裁决执行。'
                : '众裁团判定对方胜诉，请按裁决执行。',
            style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: () {
              setState(() {
                _isArbitrating = false;
                _hasApplied = false;
                _won = null;
                _myVotes = null;
                _opponentVotes = null;
                _evidenceSubmitted = false;
                _evidenceNoteController.clear();
              });
            },
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: CupertinoColors.systemGrey4,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: const Text('重新申请', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _startArbitration() async {
    setState(() => _isArbitrating = true);

    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    final random = Random();
    final win = random.nextBool();
    final mVotes = 9;
    final oVotes = 8;

    setState(() {
      _isArbitrating = false;
      _won = win;
      _myVotes = win ? mVotes : oVotes;
      _opponentVotes = win ? oVotes : mVotes;
    });

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(win ? '胜诉' : '败诉'),
        content: Text(win
            ? '恭喜！众裁团以 $_myVotes : $_opponentVotes 判定你方胜诉。\n\n对方须按裁决执行。'
            : '遗憾！众裁团以 $_opponentVotes : $_myVotes 判定对方胜诉。\n\n请按裁决执行。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
