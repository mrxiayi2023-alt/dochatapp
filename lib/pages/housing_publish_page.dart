import 'package:flutter/cupertino.dart';
import '../services/housing_service.dart';
import '../services/verification_service.dart';
import '../widgets/region_picker.dart';

class HousingPublishPage extends StatefulWidget {
  const HousingPublishPage({super.key});
  @override
  State<HousingPublishPage> createState() => _HousingPublishPageState();
}

class _HousingPublishPageState extends State<HousingPublishPage> {
  String _propertyType = '住宅';
  String _publisherType = '个人';
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  RegionSelection? _selectedRegion;
  String _layout = '1室1厅';
  final _sizeController = TextEditingController();
  final _floorController = TextEditingController();
  String _decoration = '简装';
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  final _photoCount = 0;

  static const _propertyTypes = ['住宅', '商铺', '写字楼'];
  static const _publisherTypes = ['个人', '中介'];
  static const _layouts = ['1室1厅', '2室1厅', '2室2厅', '3室1厅', '3室2厅', '4室2厅'];
  static const _decorations = ['毛坯', '简装', '精装', '豪装'];

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _sizeController.dispose();
    _floorController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('发布房源'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('房源类型'),
              _buildPropertyTypeSelector(),
              const SizedBox(height: 16),
              _buildSectionTitle('发布身份'),
              _buildPublisherTypeSelector(),
              if (_publisherType == '中介') ...[
                const SizedBox(height: 12),
                _buildTextField(_companyController, '请输入中介公司名称'),
              ],
              const SizedBox(height: 16),
              _buildSectionTitle('小区名称'),
              _buildTextField(_titleController, '请输入小区名称'),
              const SizedBox(height: 16),
              _buildSectionTitle('所在区域'),
              _buildRegionRow(),
              const SizedBox(height: 16),
              _buildSectionTitle('户型'),
              _buildPickerRow('选择户型', _layouts, _layout, (v) => setState(() => _layout = v)),
              const SizedBox(height: 16),
              _buildSectionTitle('面积'),
              _buildTextField(_sizeController, '请输入面积（m²）', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildSectionTitle('楼层'),
              _buildTextField(_floorController, '如 8/18层'),
              const SizedBox(height: 16),
              _buildSectionTitle('装修情况'),
              _buildDecorationSelector(),
              const SizedBox(height: 16),
              _buildSectionTitle('租金/售价'),
              _buildTextField(_priceController, '请输入金额（元/月）', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildSectionTitle('房源照片'),
              _buildPhotoSection(),
              const SizedBox(height: 16),
              _buildSectionTitle('房源描述'),
              _buildTextField(_descController, '请详细描述房源情况...', maxLines: 4),
              const SizedBox(height: 16),
              _buildSectionTitle('联系电话'),
              _buildTextField(_contactController, '请输入联系电话', keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _buildVerificationTip(),
              const SizedBox(height: 12),
              _buildPublishButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _propertyType,
        backgroundColor: CupertinoColors.systemGrey6,
        thumbColor: CupertinoColors.white,
        onValueChanged: (v) { if (v != null) setState(() => _propertyType = v); },
        children: Map.fromEntries(_propertyTypes.map((t) => MapEntry(t, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        )))),
      ),
    );
  }

  Widget _buildDecorationSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _decoration,
        backgroundColor: CupertinoColors.systemGrey6,
        thumbColor: CupertinoColors.white,
        onValueChanged: (v) { if (v != null) setState(() => _decoration = v); },
        children: Map.fromEntries(_decorations.map((d) => MapEntry(d, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        )))),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        maxLines: maxLines,
        padding: const EdgeInsets.all(14),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildPublisherTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _publisherType,
        backgroundColor: CupertinoColors.systemGrey6,
        thumbColor: CupertinoColors.white,
        onValueChanged: (v) { if (v != null) setState(() => _publisherType = v); },
        children: Map.fromEntries(_publisherTypes.map((t) => MapEntry(t, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        )))),
      ),
    );
  }

  Widget _buildRegionRow() {
    return GestureDetector(
      onTap: () async {
        final result = await RegionPicker.show(context, initial: _selectedRegion, maxDepth: 4);
        if (result != null) {
          setState(() => _selectedRegion = result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedRegion?.displayPath ?? '请选择省市区',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedRegion != null ? CupertinoColors.black : CupertinoColors.systemGrey,
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow(String label, List<String> options, String selected, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () => _showPicker(options, selected, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          children: [
            Expanded(child: Text(selected, style: const TextStyle(fontSize: 15))),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  void _showPicker(List<String> options, String selected, ValueChanged<String> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('完成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                onSelectedItemChanged: (i) => onChanged(options[i]),
                children: options.map((o) => Center(child: Text(o, style: const TextStyle(fontSize: 20)))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: () {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('添加图片'),
            content: const Text('最多可上传9张房源照片。\n\n当前为演示模式，图片功能暂不可用。'),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(CupertinoIcons.camera, size: 32, color: CupertinoColors.systemGrey3),
            const SizedBox(height: 8),
            Text(
              _photoCount > 0 ? '已选择 $_photoCount 张照片' : '添加房源照片（最多9张）',
              style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.info_circle, size: 16, color: CupertinoColors.systemOrange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '发布前需进行实名认证和房源核验',
              style: TextStyle(fontSize: 13, color: CupertinoColors.systemOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return CupertinoButton(
      onPressed: _submitPublish,
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      color: CupertinoColors.activeBlue,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Text('发布', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
    );
  }

  void _submitPublish() {
    if (_titleController.text.trim().isEmpty) {
      _showAlert('请填写小区名称');
      return;
    }
    if (_selectedRegion == null) {
      _showAlert('请选择所在区域');
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      _showAlert('请填写租金/售价');
      return;
    }
    if (_contactController.text.trim().isEmpty) {
      _showAlert('请填写联系电话');
      return;
    }

    VerificationService.checkVerification(
      context,
      () => _doPublish(),
      message: '发布房源需要完成实名认证，请先进行认证。',
    );
  }

  void _doPublish() {
    final size = double.tryParse(_sizeController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final listing = HousingListing(
      id: 'H${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      title: _titleController.text.trim(),
      propertyType: _propertyType,
      province: _selectedRegion?.province ?? '',
      district: _selectedRegion?.city ?? '',
      area: _selectedRegion?.district ?? '',
      town: _selectedRegion?.town ?? '',
      layout: _layout,
      size: size,
      floor: _floorController.text.trim().isNotEmpty ? _floorController.text.trim() : '待填写',
      decoration: _decoration,
      price: price,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : '暂无描述',
      contact: _contactController.text.trim(),
      verificationStatus: 'pending',
      publisherType: _publisherType,
      companyName: _publisherType == '中介' ? _companyController.text.trim() : null,
    );
    HousingService.publish(listing);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提交成功'),
        content: const Text('房源信息已提交，1-2个工作日内完成核验。\n\n核验通过后将显示在房源列表中。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }
}
