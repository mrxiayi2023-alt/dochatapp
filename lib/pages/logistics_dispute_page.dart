import 'dart:math';
import 'package:flutter/cupertino.dart';

class _Juror {
  final String name;
  final bool votedForMe;
  final String reason;
  const _Juror({required this.name, required this.votedForMe, required this.reason});
}

List<_Juror> _generateMockJury() {
  final random = Random(42);
  final names = [
    '赵一', '钱二', '孙三', '李四', '周五',
    '吴六', '郑七', '王八', '冯九', '陈十',
    '褚大', '卫小', '蒋中', '沈先', '韩后',
    '杨公', '朱明',
  ];
  final myReasons = [
    '证据充分，责任明确', '对方明显违约', '聊天记录清晰',
    '有完整的物流凭证', '时间线吻合', '货主描述可信',
    '符合行业惯例', '无其他合理解释', '以往案例类似判断',
  ];
  final opponentReasons = [
    '证据不够完整', '双方均有过错', '缺少关键凭证',
    '责任划分不清晰', '需要更多调查', '建议协商解决',
    '司机描述更合理', '部分信息存疑',
  ];
  return List.generate(17, (i) {
    final voteForMe = i < 9;
    final pool = voteForMe ? myReasons : opponentReasons;
    return _Juror(name: names[i], votedForMe: voteForMe, reason: pool[random.nextInt(pool.length)]);
  });
}

class LogisticsDisputePage extends StatefulWidget {
  const LogisticsDisputePage({super.key});
  @override
  State<LogisticsDisputePage> createState() => _LogisticsDisputePageState();
}

class _LogisticsDisputePageState extends State<LogisticsDisputePage> {
  bool _isArbitrating = false;
  bool _hasApplied = false;
  bool? _won;
  int _myVotes = 0;
  int _opponentVotes = 0;
  List<_Juror>? _jurors;
  String _evidenceType = '聊天记录';
  final _notesController = TextEditingController();
  final _evidenceNoteController = TextEditingController();
  bool _evidenceSubmitted = false;

  static const _evidenceTypes = ['聊天记录', '图片', '视频', '物流凭证', '其他'];

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
        middle: const Text('争议仲裁'),
        trailing: _hasApplied && !_isArbitrating && _won == null && _evidenceSubmitted
            ? GestureDetector(
                onTap: _startArbitration,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('发起众裁', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                ),
              )
            : null,
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
              if (_hasApplied && !_isArbitrating && _won == null) _buildEvidenceSection(),
              if (_isArbitrating) _buildArbitratingCard(),
              if (_won != null) _buildResultCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rules Card ──

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(CupertinoIcons.shield_fill, size: 22, color: CupertinoColors.systemOrange),
          SizedBox(width: 8),
          Text('众裁规则', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        const Text(
          '1. 系统将从信誉分 ≥85 的用户中随机邀请 17 位组成众裁团。\n'
          '2. 双方需提交聊天记录、图片、视频等证据及补充说明。\n'
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
          child: const Row(children: [
            Icon(CupertinoIcons.info_circle, size: 16, color: CupertinoColors.systemOrange),
            SizedBox(width: 6),
            Expanded(
              child: Text('温馨提示：虚假申请将扣除信誉分，严重者冻结账户。',
                  style: TextStyle(fontSize: 12, color: CupertinoColors.systemOrange)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildApplyButton() {
    return CupertinoButton(
      onPressed: () => setState(() => _hasApplied = true),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      color: CupertinoColors.destructiveRed,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Text('申请争议仲裁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
    );
  }

  // ── Evidence Section ──

  Widget _buildEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(CupertinoIcons.doc_text_fill, size: 20, color: CupertinoColors.activeBlue),
          SizedBox(width: 8),
          Text('提交证据', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        const Text('证据类型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _evidenceTypes.map((type) {
              final sel = type == _evidenceType;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _evidenceType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? CupertinoColors.activeBlue : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(16),
                      border: sel ? null : Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Text(type,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        const Text('补充说明', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _evidenceNoteController,
          placeholder: '请描述争议经过及诉求...',
          placeholderStyle: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          style: const TextStyle(fontSize: 13),
          maxLines: 4,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          padding: const EdgeInsets.all(10),
        ),
        const SizedBox(height: 12),
        const Text('争议描述', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _notesController,
          placeholder: '描述您期望的解决方案...',
          placeholderStyle: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          style: const TextStyle(fontSize: 13),
          maxLines: 3,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          padding: const EdgeInsets.all(10),
        ),
        const SizedBox(height: 16),
        CupertinoButton(
          onPressed: () {
            setState(() => _evidenceSubmitted = true);
            _showToast('证据已提交，您可以发起众裁了');
          },
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          color: CupertinoColors.activeBlue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _evidenceSubmitted ? '证据已提交 ✓' : '提交证据',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.white),
          ),
        ),
      ]),
    );
  }

  // ── Custom Progress Bar ──

  Widget _buildProgressBar(double factor, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(children: [
          SizedBox(width: double.infinity, child: Container(color: CupertinoColors.systemGrey5)),
          FractionallySizedBox(
            widthFactor: factor.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ]),
      ),
    );
  }

  // ── Arbitrating Card ──

  Widget _buildArbitratingCard() {
    const target = 9;
    final myProgress = _myVotes / target;
    final oppProgress = _opponentVotes / target;

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(CupertinoIcons.person_3_fill, size: 22, color: CupertinoColors.systemOrange),
            SizedBox(width: 8),
            Text('众裁投票中', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                  border: Border.all(color: CupertinoColors.systemGreen, width: 3),
                ),
                alignment: Alignment.center,
                child: Text('$_myVotes',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: CupertinoColors.systemGreen)),
              ),
              const SizedBox(height: 6),
              const Text('我方票数', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
            ]),
            const Text('VS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.systemGrey3)),
            Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                  border: Border.all(color: CupertinoColors.destructiveRed, width: 3),
                ),
                alignment: Alignment.center,
                child: Text('$_opponentVotes',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
              ),
              const SizedBox(height: 6),
              const Text('对方票数', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
            ]),
          ]),
          const SizedBox(height: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('我方', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGreen, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(child: _buildProgressBar(myProgress, CupertinoColors.systemGreen)),
              const SizedBox(width: 8),
              Text('$_myVotes/$target', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('对方', style: TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(child: _buildProgressBar(oppProgress, CupertinoColors.destructiveRed)),
              const SizedBox(width: 8),
              Text('$_opponentVotes/$target', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            child: Text('先获得 $target 票者胜出 · 当前共 ${_myVotes + _opponentVotes}/17 票',
                style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      if (_jurors != null) ...[
        _buildSectionHeader(),
        const SizedBox(height: 8),
        ...List.generate(_jurors!.length, (i) => _buildJurorCard(_jurors![i], i)),
      ],
    ]);
  }

  Widget _buildJurorCard(_Juror juror, int index) {
    final green = juror.votedForMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: green
              ? CupertinoColors.systemGreen.withValues(alpha: 0.3)
              : CupertinoColors.destructiveRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: green
                ? CupertinoColors.systemGreen.withValues(alpha: 0.15)
                : CupertinoColors.destructiveRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text('${index + 1}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: green ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(juror.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: green
                      ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                      : CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(green ? '支持我方' : '支持对方',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: green ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(juror.reason,
                style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Icon(green ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
            size: 18, color: green ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed),
      ]),
    );
  }

  Widget _buildResultCard() {
    final won = _won!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: won
            ? CupertinoColors.systemGreen.withValues(alpha: 0.06)
            : CupertinoColors.destructiveRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: won
              ? CupertinoColors.systemGreen.withValues(alpha: 0.3)
              : CupertinoColors.destructiveRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(children: [
        Icon(won ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
            size: 48, color: won ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed),
        const SizedBox(height: 12),
        Text(won ? '胜诉 🎉' : '败诉',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: won ? CupertinoColors.systemGreen : CupertinoColors.destructiveRed)),
        const SizedBox(height: 8),
        Text('最终比分 $_myVotes : $_opponentVotes', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          won ? '众裁团支持了您的诉求，裁决具有平台约束力。' : '众裁团未支持您的诉求，建议与对方协商后续方案。',
          style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  void _startArbitration() {
    final jurors = _generateMockJury();
    setState(() {
      _isArbitrating = true;
      _jurors = jurors;
      _myVotes = 0;
      _opponentVotes = 0;
    });
    _animateVotes(jurors);
  }

  Future<void> _animateVotes(List<_Juror> jurors) async {
    int myCount = 0;
    int oppCount = 0;
    for (int i = 0; i < jurors.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (jurors[i].votedForMe) { myCount++; } else { oppCount++; }
      setState(() {
        _myVotes = myCount;
        _opponentVotes = oppCount;
      });
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _won = _myVotes >= 9;
      _isArbitrating = false;
    });
  }

  Widget _buildSectionHeader() {
    return Row(children: [
      const Icon(CupertinoIcons.person_3_fill, size: 16, color: CupertinoColors.systemOrange),
      const SizedBox(width: 6),
      const Text('陪审团成员', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('17人', style: TextStyle(fontSize: 10, color: CupertinoColors.systemOrange)),
      ),
    ]);
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }
}
