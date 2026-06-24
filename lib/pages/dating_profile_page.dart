// 电波灵动即时通讯系统 V1.0
// 开发完成日期：2026年6月24日
// 文件说明：婚恋个人展示页（V2 - 照片墙/视频/语音/完整信息/编辑）

import 'package:flutter/cupertino.dart';
import '../services/dating_service.dart';

class DatingProfilePage extends StatefulWidget {
  final DatingUser user;
  const DatingProfilePage({super.key, required this.user});
  @override
  State<DatingProfilePage> createState() => _DatingProfilePageState();
}

class _DatingProfilePageState extends State<DatingProfilePage> {
  late DatingUser _user;
  bool _editing = false;
  @override
  void initState() { super.initState(); _user = widget.user; }
  DatingUser get user => _user;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(_editing ? '编辑资料' : user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: user.isSelf
            ? CupertinoButton(padding: EdgeInsets.zero, child: Text(_editing ? '完成' : '编辑', style: const TextStyle(fontSize: 16)), onPressed: () => setState(() => _editing = !_editing))
            : null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            const SizedBox(height: 16),
            if (!_editing) _buildPhotoWall(),
            if (!_editing) const SizedBox(height: 12),
            if (!_editing) _buildMediaBadges(),
            if (!_editing) const SizedBox(height: 12),
            if (!_editing) _buildBasicInfo(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildVerificationCard(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildTagsAndInterests(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildIntroCard(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildDatingCriteriaCard(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildLoveQACard(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildScoreCard(),
            if (!_editing) const SizedBox(height: 8),
            if (!_editing) _buildActionButtons(),
            if (_editing) _buildEditForm(),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ---------- Photo Wall ----------

  Widget _buildPhotoWall() {
    final photos = user.photos;
    final displayPhotos = photos.isNotEmpty ? photos : List<String>.filled(1, '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('照片', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
          Text('${displayPhotos.length}/9', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3)),
        ]),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemCount: displayPhotos.length.clamp(0, 9),
          itemBuilder: (ctx, i) {
            if (i == 0 && displayPhotos[i].isEmpty) {
              return Container(
                decoration: BoxDecoration(color: user.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(user.initial, style: TextStyle(color: user.color, fontSize: 28, fontWeight: FontWeight.w700)),
                  if (i == 0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: user.color, borderRadius: BorderRadius.circular(4)), child: const Text('封面', style: TextStyle(color: CupertinoColors.white, fontSize: 9))),
                ]),
              );
            }
            return GestureDetector(
              onTap: () => _showPhoto(i),
              child: Stack(children: [
                Container(decoration: BoxDecoration(color: user.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Icon(CupertinoIcons.photo_fill, size: 32, color: user.color.withOpacity(0.3)))),
                if (i == 0) Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: user.color, borderRadius: BorderRadius.circular(4)), child: const Text('封面', style: TextStyle(color: CupertinoColors.white, fontSize: 9)))),
              ]),
            );
          },
        ),
      ]),
    );
  }

  // ---------- Media Badges ----------

  Widget _buildMediaBadges() {
    if (!user.hasVideo && !user.hasVoiceIntro) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        if (user.hasVideo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: CupertinoColors.activeBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.3))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.play_rectangle_fill, size: 16, color: CupertinoColors.activeBlue),
              SizedBox(width: 4),
              Text('个人视频', style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue, fontWeight: FontWeight.w500)),
            ]),
          ),
        if (user.hasVideo && user.hasVoiceIntro) const SizedBox(width: 8),
        if (user.hasVoiceIntro)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: CupertinoColors.systemGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: CupertinoColors.systemGreen.withOpacity(0.3))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.mic_fill, size: 16, color: CupertinoColors.systemGreen),
              SizedBox(width: 4),
              Text('语音介绍', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGreen, fontWeight: FontWeight.w500)),
            ]),
          ),
      ]),
    );
  }

  // ---------- Basic Info ----------

  Widget _buildBasicInfo() {
    return _card(
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: user.color, shape: BoxShape.circle), alignment: Alignment.center,
            child: Text(user.initial, style: const TextStyle(color: CupertinoColors.white, fontSize: 24, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text('  ${user.age}歳', style: const TextStyle(fontSize: 17, color: CupertinoColors.systemGrey)),
              const SizedBox(width: 6),
              if (user.isOnline) Container(width: 8, height: 8, decoration: const BoxDecoration(color: CupertinoColors.systemGreen, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              if (user.gender.isNotEmpty) Text(user.gender, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              if (user.height > 0) Text(' · ${user.height}cm', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              if (user.education.isNotEmpty) Text(' · ${user.education}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            ]),
          ])),
          GestureDetector(
            onTap: () => _showScoreDetail(),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: CupertinoColors.systemOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: CupertinoColors.systemOrange.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(CupertinoIcons.star_fill, size: 12, color: CupertinoColors.systemOrange),
                const SizedBox(width: 2),
                Text('${user.score}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange)),
              ])),
          ),
        ]),
        const SizedBox(height: 10),
        if (user.occupation.isNotEmpty) _infoRow(CupertinoIcons.bag_fill, '职业', user.occupation),
        if (user.income.isNotEmpty) _infoRow(CupertinoIcons.money_dollar_circle_fill, '收入', user.income),
        if (user.birthplace.isNotEmpty) _infoRow(CupertinoIcons.house_fill, '籍贯', user.birthplace),
        if (user.currentLocation.isNotEmpty) _infoRow(CupertinoIcons.location_fill, '现居', user.currentLocation),
        if (user.maritalStatus.isNotEmpty) _infoRow(CupertinoIcons.doc_text_fill, '婚姻', user.maritalStatus),
        if (user.distance > 0) _infoRow(CupertinoIcons.location_solid, '距离', '${user.distance.toInt()}km'),
        if (user.lastActive.isNotEmpty) _infoRow(CupertinoIcons.clock_solid, '活跃', user.lastActive),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
      Icon(icon, size: 14, color: CupertinoColors.systemGrey3),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    ]));
  }

  // ---------- Verification ----------

  Widget _buildVerificationCard() {
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('安全认证', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      _verifyItem(CupertinoIcons.person_crop_circle_badge_checkmark, '实名认证', user.isRealNameVerified, '已认证', '未认证'),
      const SizedBox(height: 6),
      _verifyItem(CupertinoIcons.camera_viewfinder, '人脸识别', user.isFaceVerified, '已通过', '未通过'),
      const SizedBox(height: 6),
      _verifyItem(CupertinoIcons.doc_text_fill, '单身承诺', user.isSingleCommitmentSigned, '已签署', '未签署'),
    ]));
  }

  Widget _verifyItem(IconData icon, String label, bool passed, String passText, String failText) {
    final color = passed ? CupertinoColors.systemGreen : CupertinoColors.systemOrange;
    return Row(children: [
      Icon(icon, size: 18, color: CupertinoColors.systemGrey), const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      Icon(passed ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.exclamationmark_triangle_fill, size: 16, color: color),
      const SizedBox(width: 4),
      Text(passed ? passText : failText, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
    ]);
  }

  // ---------- Tags & Interests ----------

  Widget _buildTagsAndInterests() {
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (user.tags.isNotEmpty) ...[
        const Text('个性标签', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: user.tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: user.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Text(t, style: TextStyle(fontSize: 13, color: user.color, fontWeight: FontWeight.w500)),
        )).toList()),
      ],
      if (user.interests.isNotEmpty) ...[
        if (user.tags.isNotEmpty) const SizedBox(height: 12),
        const Text('兴趣爱好', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: user.interests.map((i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: CupertinoColors.systemBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: Text(i, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemBlue, fontWeight: FontWeight.w500)),
        )).toList()),
      ],
    ]));
  }

  // ---------- Intro ----------

  Widget _buildIntroCard() {
    if (user.intro.isEmpty) return const SizedBox.shrink();
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('个人介绍', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(user.intro, style: const TextStyle(fontSize: 14, height: 1.5)),
    ]));
  }

  // ---------- Dating Criteria ----------

  Widget _buildDatingCriteriaCard() {
    final has = user.criteriaAgeMin > 0 || user.criteriaEducation.isNotEmpty || user.criteriaLocation.isNotEmpty;
    if (!has) return const SizedBox.shrink();
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('择偶标准', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (user.criteriaAgeMin > 0) _criteriaItem('年龄', '${user.criteriaAgeMin}-${user.criteriaAgeMax}岁'),
      if (user.criteriaHeightMin > 0) _criteriaItem('身高', '${user.criteriaHeightMin}-${user.criteriaHeightMax}cm'),
      if (user.criteriaEducation.isNotEmpty) _criteriaItem('学历', user.criteriaEducation),
      if (user.criteriaIncome.isNotEmpty) _criteriaItem('收入', user.criteriaIncome),
      if (user.criteriaLocation.isNotEmpty) _criteriaItem('地域', user.criteriaLocation),
    ]));
  }

  Widget _criteriaItem(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
      Text('$label: ', style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    ]));
  }

  // ---------- Love Q&A ----------

  Widget _buildLoveQACard() {
    if (user.loveQA.isEmpty) return const SizedBox.shrink();
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('恋爱问答', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...user.loveQA.map((qa) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: CupertinoColors.systemBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(qa.question, style: const TextStyle(fontSize: 13, color: CupertinoColors.activeBlue, fontWeight: FontWeight.w500))),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.only(left: 10), child: Text(qa.answer, style: const TextStyle(fontSize: 14, height: 1.4))),
        ]),
      )),
    ]));
  }

  // ---------- Score Card ----------

  Widget _buildScoreCard() {
    return GestureDetector(
      onTap: () => _showScoreDetail(),
      child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('恋爱分数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Row(children: [
            Text('${user.score}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CupertinoColors.systemOrange)),
            const Text(' / 100', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
            const SizedBox(width: 4), const Icon(CupertinoIcons.info_circle, size: 14, color: CupertinoColors.systemGrey3),
          ]),
        ]),
        const SizedBox(height: 10),
        _miniScoreBar('真实性', user.realnessScore, 40, CupertinoColors.systemGreen),
        const SizedBox(height: 4),
        _miniScoreBar('互动度', user.interactionScore, 30, CupertinoColors.systemBlue),
        const SizedBox(height: 4),
        _miniScoreBar('完整度', user.completenessScore, 20, CupertinoColors.systemOrange),
        const SizedBox(height: 4),
        _miniScoreBar('诚信分', user.integrityScore, 10, CupertinoColors.systemPurple),
      ])),
    );
  }

  Widget _miniScoreBar(String label, int score, int max, Color color) {
    final r = (score / max).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 48, child: Text(label, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: Container(height: 6, color: CupertinoColors.systemGrey5, child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: r, child: Container(color: color))))),
      SizedBox(width: 48, child: Text('$score/$max', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500))),
    ]);
  }

  // ---------- Action Buttons ----------

  Widget _buildActionButtons() {
    if (user.isSelf) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: CupertinoButton(borderRadius: const BorderRadius.all(Radius.circular(22)), color: CupertinoColors.systemGreen,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.heart_fill, size: 18, color: CupertinoColors.white), SizedBox(width: 4), Text('喜欢', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600))]),
            onPressed: () { DatingService.like(user.userId); _showToast('已喜欢'); },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(borderRadius: const BorderRadius.all(Radius.circular(22)), color: CupertinoColors.activeBlue,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.chat_bubble_fill, size: 18, color: CupertinoColors.white), SizedBox(width: 4), Text('聊天', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600))]),
            onPressed: () => _showToast(user.isMutualMatch ? '开启聊天' : '需要互相喜欢才能聊天'),
          ),
        ),
      ]),
    );
  }

  void _showToast(String msg) {
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
      content: Text(msg),
      actions: [CupertinoDialogAction(child: const Text('好的'), onPressed: () => Navigator.of(ctx).pop())],
    ));
  }

  // ---------- Edit Form ----------

  Widget _buildEditForm() {
    final nameCtl = TextEditingController(text: _user.name);
    final introCtl = TextEditingController(text: _user.intro);
    String editGender = _user.gender;
    int editAge = _user.age;
    int editHeight = _user.height;
    String editEducation = _user.education;
    String editOccupation = _user.occupation;
    String editIncome = _user.income;
    String editMarital = _user.maritalStatus;
    String editBirthplace = _user.birthplace;
    String editLocation = _user.currentLocation;
    List<String> editTags = List.from(_user.tags);
    List<String> editInterests = List.from(_user.interests);
    String editCriteriaAge = _user.criteriaAgeMin > 0 ? (_user.criteriaAgeMin.toString() + '-' + _user.criteriaAgeMax.toString()) : '';
    String editCriteriaHeight = _user.criteriaHeightMin > 0 ? (_user.criteriaHeightMin.toString() + '-' + _user.criteriaHeightMax.toString()) : '';
    String editCriteriaEdu = _user.criteriaEducation;
    String editCriteriaIncome = _user.criteriaIncome;
    String editCriteriaLoc = _user.criteriaLocation;

    return StatefulBuilder(
      builder: (ctx, setInnerState) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _editField('昵称', CupertinoTextField(controller: nameCtl, placeholder: '请输入昵称', padding: const EdgeInsets.all(12))),
          const SizedBox(height: 12),
          _editField('性别', _buildSelectField(editGender.isEmpty ? '请选择' : editGender, () => _showPicker(['男', '女'], (v) { editGender = v; setInnerState((){}); }))),
          const SizedBox(height: 12),
          _editField('年龄', _buildSelectField(editAge > 0 ? (editAge.toString() + '岁') : '请选择', () => _showAgePicker((v) { editAge = v; setInnerState((){}); }))),
          const SizedBox(height: 12),
          _editField('身高', _buildSelectField(editHeight > 0 ? (editHeight.toString() + ' cm') : '请选择', () => _showHeightPicker((v) { editHeight = v; setInnerState((){}); }))),
          const SizedBox(height: 12),
          _editField('学历', _buildSelectField(editEducation.isEmpty ? '请选择' : editEducation, () => _showPicker((['高中','大专','本科','硕士','博士']), (v) { editEducation = v; setInnerState((){}); }))),
          const SizedBox(height: 12),
          _editField('职业', CupertinoTextField(controller: TextEditingController(text: editOccupation), placeholder: '请输入职业', padding: const EdgeInsets.all(12), onChanged: (v) => editOccupation = v)),
          const SizedBox(height: 12),
          _editField('收入', _buildSelectField(editIncome.isEmpty ? '请选择' : editIncome, () => _showPicker((['5K以下','5-10K','10-20K','20-50K','50K以上']), (v) { editIncome = v; setInnerState((){}); }))),
          const SizedBox(height: 12),
          _editField('婚姻', _buildSelectField(editMarital.isEmpty ? '请选择' : editMarital, () => _showPicker((['未婚','离异','丧偶']), (v) { editMarital = v; setInnerState((){}); }))),
          const SizedBox(height: 12),
          _editField('籍贯', CupertinoTextField(controller: TextEditingController(text: editBirthplace), placeholder: '请输入籍贯', padding: const EdgeInsets.all(12), onChanged: (v) => editBirthplace = v)),
          const SizedBox(height: 12),
          _editField('现居地', CupertinoTextField(controller: TextEditingController(text: editLocation), placeholder: '请输入现居地', padding: const EdgeInsets.all(12), onChanged: (v) => editLocation = v)),
          const SizedBox(height: 12),
          _editField('个性标签', _buildTagEditor(editTags, setInnerState)),
          const SizedBox(height: 12),
          _editField('兴趣爱好', _buildInterestSelector(editInterests, setInnerState)),
          const SizedBox(height: 12),
          _editField('个人介绍', CupertinoTextField(controller: introCtl, placeholder: '介绍一下自己（200字以内）', maxLines: 3, maxLength: 200, padding: const EdgeInsets.all(12))),
          const SizedBox(height: 16),
          const Text('择偶标准', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _editField('年龄范围', CupertinoTextField(controller: TextEditingController(text: editCriteriaAge), placeholder: '如: 22-32', padding: const EdgeInsets.all(12), onChanged: (v) => editCriteriaAge = v)),
          const SizedBox(height: 8),
          _editField('身高范围', CupertinoTextField(controller: TextEditingController(text: editCriteriaHeight), placeholder: '如: 160-175', padding: const EdgeInsets.all(12), onChanged: (v) => editCriteriaHeight = v)),
          const SizedBox(height: 8),
          _editField('学历要求', _buildSelectField(editCriteriaEdu.isEmpty ? '不限' : editCriteriaEdu, () => _showPicker((['不限','高中','大专','本科','硕士','博士']), (v) { editCriteriaEdu = v; setInnerState((){}); }))),
          const SizedBox(height: 8),
          _editField('收入要求', _buildSelectField(editCriteriaIncome.isEmpty ? '不限' : editCriteriaIncome, () => _showPicker((['不限','5K以下','5-10K','10-20K','20-50K','50K以上']), (v) { editCriteriaIncome = v; setInnerState((){}); }))),
          const SizedBox(height: 8),
          _editField('地域要求', CupertinoTextField(controller: TextEditingController(text: editCriteriaLoc), placeholder: '如: 上海', padding: const EdgeInsets.all(12), onChanged: (v) => editCriteriaLoc = v)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: CupertinoButton(
            color: CupertinoColors.activeBlue,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: const Text('保存资料', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600)),
            onPressed: () {
              final ageMatch = RegExp(r'(\\d+)\\s*-\\s*(\\d+)').firstMatch(editCriteriaAge);
              final heightMatch = RegExp(r'(\\d+)\\s*-\\s*(\\d+)').firstMatch(editCriteriaHeight);
              setState(() {
                _user = _user.copyWith(
                  name: nameCtl.text, gender: editGender, age: editAge, height: editHeight,
                  education: editEducation, occupation: editOccupation, income: editIncome,
                  maritalStatus: editMarital, birthplace: editBirthplace, currentLocation: editLocation,
                  tags: editTags, interests: editInterests, intro: introCtl.text,
                  criteriaAgeMin: ageMatch != null ? int.parse(ageMatch.group(1)!) : 0,
                  criteriaAgeMax: ageMatch != null ? int.parse(ageMatch.group(2)!) : 0,
                  criteriaHeightMin: heightMatch != null ? int.parse(heightMatch.group(1)!) : 0,
                  criteriaHeightMax: heightMatch != null ? int.parse(heightMatch.group(2)!) : 0,
                  criteriaEducation: editCriteriaEdu, criteriaIncome: editCriteriaIncome, criteriaLocation: editCriteriaLoc,
                );
                _editing = false;
              });
              _showToast('资料已保存');
            },
          )),
        ]),
      ),
    );
  }

  Widget _editField(String label, Widget field) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
      const SizedBox(height: 4), field,
    ]);
  }

  Widget _buildSelectField(String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: CupertinoColors.systemGrey4)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(value, style: TextStyle(fontSize: 15, color: (value == '请选择' || value == '不限') ? CupertinoColors.systemGrey3 : CupertinoColors.black)),
          const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey3),
        ]),
      ),
    );
  }

  // ---------- Tag Editor ----------

  Widget _buildTagEditor(List<String> tags, void Function(void Function()) setInnerState) {
    final ctl = TextEditingController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        ...tags.map((t) => Container(
          margin: const EdgeInsets.only(right: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: user.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(t, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () { tags.remove(t); setInnerState((){}); },
              child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
            ),
          ]),
        )),
        if (tags.length < 5)
          GestureDetector(
            onTap: () {
              showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
                title: const Text('添加标签'),
                content: CupertinoTextField(controller: ctl, placeholder: '输入标签'),
                actions: [
                  CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.of(ctx).pop()),
                  CupertinoDialogAction(child: const Text('添加'), onPressed: () {
                    if (ctl.text.trim().isNotEmpty && tags.length < 5) { tags.add(ctl.text.trim()); ctl.clear(); setInnerState((){}); }
                    Navigator.of(ctx).pop();
                  }),
                ],
              ));
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(20), color: CupertinoColors.systemGrey6),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.plus, size: 14), SizedBox(width: 2), Text('添加', style: TextStyle(fontSize: 12))]),
            ),
          ),
      ]),
    ]);
  }

  // ---------- Interest Selector ----------

  Widget _buildInterestSelector(List<String> interests, void Function(void Function()) setInnerState) {
    final allInterests = ['运动','音乐','电影','阅读','旅行','美食','摄影','游戏','宠物','手工'];
    return Wrap(spacing: 6, runSpacing: 6, children: allInterests.map((i) {
      final sel = interests.contains(i);
      return GestureDetector(
        onTap: () { if (sel) interests.remove(i); else interests.add(i); setInnerState((){}); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: sel ? CupertinoColors.activeBlue : CupertinoColors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4)),
          child: Text(i, style: TextStyle(fontSize: 13, color: sel ? CupertinoColors.white : CupertinoColors.black)),
        ),
      );
    }).toList());
  }

  // ---------- Pickers ----------

  void _showPicker(List<String> options, ValueChanged<String> onSelect) {
    showCupertinoModalPopup(context: context, builder: (ctx) => CupertinoActionSheet(
      actions: options.map((o) => CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); onSelect(o); }, child: Text(o))).toList(),
      cancelButton: CupertinoActionSheetAction(child: const Text('取消'), isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop()),
    ));
  }

  void _showAgePicker(ValueChanged<int> onSelect) {
    showCupertinoModalPopup(context: context, builder: (ctx) => SizedBox(
      height: 250, child: Column(children: [
        CupertinoNavigationBar(middle: const Text('选择年龄'), trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Text('确定'), onPressed: () => Navigator.of(ctx).pop())),
        Expanded(child: CupertinoPicker(itemExtent: 36, onSelectedItemChanged: (i) => onSelect(18 + i),
          children: List.generate(43, (i) => Center(child: Text((18 + i).toString() + '岁', style: const TextStyle(fontSize: 18)))))),
      ]),
    ));
  }

  void _showHeightPicker(ValueChanged<int> onSelect) {
    showCupertinoModalPopup(context: context, builder: (ctx) => SizedBox(
      height: 250, child: Column(children: [
        CupertinoNavigationBar(middle: const Text('选择身高'), trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Text('确定'), onPressed: () => Navigator.of(ctx).pop())),
        Expanded(child: CupertinoPicker(itemExtent: 36, onSelectedItemChanged: (i) => onSelect(140 + i),
          children: List.generate(71, (i) => Center(child: Text((140 + i).toString() + 'cm', style: const TextStyle(fontSize: 18)))))),
      ]),
    ));
  }

  // ---------- Helpers ----------

  Widget _card(Widget child) {
    return Container(width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)), child: child);
  }

  void _showPhoto(int index) {
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
      content: Container(height: 300, color: user.color.withOpacity(0.1), alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('照片 ' + (index + 1).toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Icon(CupertinoIcons.photo_fill, size: 64, color: CupertinoColors.systemGrey4),
        ])),
      actions: [CupertinoDialogAction(child: const Text('关闭'), onPressed: () => Navigator.of(ctx).pop())],
    ));
  }

  void _showScoreDetail() {
    showCupertinoModalPopup(context: context, builder: (ctx) => CupertinoActionSheet(
      title: Text(user.name + ' 的综合评分'),
      message: Column(children: [
        _scorePopupItem('真实性', user.realnessScore, 40, '身份证+姓名+人脸认证', CupertinoColors.systemGreen),
        _scorePopupItem('互动度', user.interactionScore, 30, '回复率+在线时长+主动发起', CupertinoColors.systemBlue),
        _scorePopupItem('完整度', user.completenessScore, 20, '资料完整度评分', CupertinoColors.systemOrange),
        _scorePopupItem('诚信分', user.integrityScore, 10, '未被举报则为满分', CupertinoColors.systemPurple),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('总分: ' + user.score.toString() + '/100', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      ]),
      cancelButton: CupertinoActionSheetAction(child: const Text('关闭'), onPressed: () => Navigator.of(ctx).pop()),
    ));
  }

  Widget _scorePopupItem(String label, int score, int max, String desc, Color color) {
    final r = (score / max).clamp(0.0, 1.0);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(score.toString() + '/' + max.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(borderRadius: BorderRadius.circular(2), child: Container(height: 6, color: CupertinoColors.systemGrey5, child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: r, child: Container(color: color)))),
        Text(desc, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
      ]),
    );
  }
}
