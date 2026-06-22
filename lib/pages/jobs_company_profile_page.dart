import 'package:flutter/cupertino.dart';
import '../widgets/region_picker.dart';
import 'jobs_page.dart';

const _industries = [
  '互联网', '电子商务', '金融', '教育', '医疗', '制造',
  '房地产', '物流', '餐饮', '零售', '媒体', '法律',
  '咨询', '能源', '农业', '建筑', '交通', '旅游', '其他',
];

const _scales = ['1-20人', '20-99人', '100-499人', '500人以上'];

const _knownCompanies = [
  '智云科技', '星辰软件', '未来科技', '设计工坊', '云测技术',
  '华为技术', '腾讯科技', '阿里巴巴', '字节跳动', '百度网络',
  '京东集团', '美团点评', '网易网络', '小米科技', '拼多多',
  '滴滴出行', '快手科技', '哔哩哔哩', '商汤科技', '大疆创新',
];

class JobsCompanyProfilePage extends StatefulWidget {
  const JobsCompanyProfilePage({super.key});

  @override
  State<JobsCompanyProfilePage> createState() => _JobsCompanyProfilePageState();
}

class _JobsCompanyProfilePageState extends State<JobsCompanyProfilePage> {
  final _nameCtrl = TextEditingController(text: '智云科技');
  String _industry = '互联网';
  String _scale = '20-99人';
  final _descCtrl = TextEditingController(text: '智云科技成立于2018年，是一家专注于企业级SaaS解决方案的高新技术企业。公司核心团队来自BAT等一线互联网公司，致力于通过技术创新帮助企业实现数字化转型。');
  RegionSelection? _addressRegion;
  final _detailAddrCtrl = TextEditingController(text: '文昌西路525号A座3层');

  bool _saved = false;
  bool _nameVerified = true; // 智云科技 is in the known list
  bool _namePending = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final text = _nameCtrl.text.trim();
    setState(() {
      _nameVerified = _knownCompanies.contains(text);
      _namePending = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _detailAddrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('公司资料'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStorefrontSection(),
              const SizedBox(height: 16),
              _buildCard('基本信息', [
                _buildSectionRow('公司名称', _buildNameField()),
                if (!_nameVerified && _nameCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle, size: 14, color: CupertinoColors.systemOrange),
                        SizedBox(width: 6),
                        Expanded(child: Text('未匹配到工商信息，请提交营业执照人工审核', style: TextStyle(fontSize: 12, color: CupertinoColors.systemOrange))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _buildSectionRow('所属行业', _buildIndustryPicker()),
                const SizedBox(height: 14),
                _buildSectionRow('企业规模', _buildScalePicker()),
              ]),
              const SizedBox(height: 16),
              _buildCard('公司简介', [
                _buildMultiField(_descCtrl, '请描述公司的业务范围、发展历程等...'),
              ]),
              const SizedBox(height: 16),
              _buildCard('公司地址', [
                _buildSectionRow('所在区域', _buildRegionPicker()),
                const SizedBox(height: 14),
                _buildSectionRow('详细地址', _buildField(_detailAddrCtrl, '如XX路XX号XX栋XX室')),
              ]),
              const SizedBox(height: 16),
              _buildCard('企业资质', [
                _buildSectionRow('营业执照', _buildLicenseUpload()),
              ]),
              const SizedBox(height: 24),
              CupertinoButton(
                onPressed: _save,
                borderRadius: const BorderRadius.all(Radius.circular(22)),
                color: CupertinoColors.activeBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text('保存', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
              ),
              if (_saved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_namePending ? CupertinoColors.systemOrange : CupertinoColors.systemGreen).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _namePending ? CupertinoIcons.clock : CupertinoIcons.checkmark_circle_fill,
                        size: 18,
                        color: _namePending ? CupertinoColors.systemOrange : CupertinoColors.systemGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _namePending ? '审核中' : '公司资料已保存',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _namePending ? CupertinoColors.systemOrange : CupertinoColors.systemGreen),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorefrontSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUploadBlock('门头照片', CupertinoIcons.camera, '上传门头照片'),
        const SizedBox(width: 20),
        _buildUploadBlock('营业执照', CupertinoIcons.doc, '上传营业执照'),
      ],
    );
  }

  Widget _buildUploadBlock(String label, IconData icon, String dialogTitle) {
    return GestureDetector(
      onTap: () => _showUploadDialog(dialogTitle),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey4, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 30, color: CupertinoColors.systemGrey3),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  void _showUploadDialog(String title) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: const Text('请上传清晰的图片。当前为演示模式，图片功能暂不可用。'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoTextField(
        controller: _nameCtrl,
        placeholder: '请输入公司名称',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        style: const TextStyle(fontSize: 15),
        suffix: _nameCtrl.text.trim().isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  _nameVerified ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.exclamationmark_circle,
                  size: 18,
                  color: _nameVerified ? CupertinoColors.systemGreen : CupertinoColors.systemOrange,
                ),
              ),
      ),
    );
  }

  Widget _buildLicenseUpload() {
    return GestureDetector(
      onTap: () => _showUploadDialog('上传营业执照'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(CupertinoIcons.doc_fill, size: 20, color: CupertinoColors.systemGrey3),
            SizedBox(width: 10),
            Expanded(child: Text('点击上传营业执照照片', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
            Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionRow(String label, Widget child) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String placeholder) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoTextField(
        controller: ctrl,
        placeholder: placeholder,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildMultiField(TextEditingController ctrl, String placeholder) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoTextField(
        controller: ctrl,
        placeholder: placeholder,
        maxLines: 5,
        padding: const EdgeInsets.all(12),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildIndustryPicker() {
    return GestureDetector(
      onTap: () => _showIndustrySheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(_industry, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _showIndustrySheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择所属行业'),
        actions: _industries.map((ind) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() => _industry = ind);
            Navigator.of(ctx).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_industry == ind)
                const Icon(CupertinoIcons.checkmark, size: 18, color: CupertinoColors.activeBlue)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(ind, style: TextStyle(
                fontSize: 16,
                fontWeight: _industry == ind ? FontWeight.w600 : FontWeight.w400,
                color: _industry == ind ? CupertinoColors.activeBlue : CupertinoColors.black,
              )),
            ],
          ),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildScalePicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _scale,
        backgroundColor: const Color(0xFFF2F2F7),
        thumbColor: CupertinoColors.white,
        onValueChanged: (v) { if (v != null) setState(() => _scale = v); },
        children: Map.fromEntries(_scales.map((s) => MapEntry(s, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        )))),
      ),
    );
  }

  Widget _buildRegionPicker() {
    return GestureDetector(
      onTap: () async {
        final result = await RegionPicker.show(context, initial: _addressRegion, maxDepth: 4);
        if (result != null && context.mounted) {
          setState(() => _addressRegion = result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(
              _addressRegion?.displayPath ?? '请选择所在区域',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _addressRegion != null ? CupertinoColors.black : CupertinoColors.systemGrey),
            )),
            const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showAlert('请填写公司名称');
      return;
    }
    if (!_nameVerified) {
      setState(() { _namePending = true; _saved = true; });
      hasCompanyProfile = true; // 标记企业资料已设置
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('已提交审核'),
          content: const Text('公司名称未匹配到工商信息，已提交营业执照人工审核。\n\n预计1-3个工作日内完成审核。'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
          ],
        ),
      );
      return;
    }
    setState(() => _saved = true);
    hasCompanyProfile = true; // 标记企业资料已设置
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('保存成功'),
        content: const Text('公司资料已更新。完善资料后即可发布职位。'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }

  void _showAlert(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }
}
