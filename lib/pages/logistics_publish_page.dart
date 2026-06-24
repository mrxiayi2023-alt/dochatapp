import 'package:flutter/cupertino.dart';

const _cargoTypes = ['普通货物', '生鲜冷链', '易碎品', '危险品', '贵重物品', '大件物品'];
const _vehicleTypes = ['小面', '中面', '厢货', '平板', '冷藏'];
const _weightOptions = ['≤100kg', '100-500kg', '500kg-1吨', '1-3吨', '3-5吨', '5-10吨', '>10吨'];
const _volumeOptions = ['≤1m³', '1-3m³', '3-5m³', '5-10m³', '10-20m³', '>20m³'];

class LogisticsPublishPage extends StatefulWidget {
  const LogisticsPublishPage({super.key});
  @override
  State<LogisticsPublishPage> createState() => _LogisticsPublishPageState();
}

class _LogisticsPublishPageState extends State<LogisticsPublishPage> {
  final _goodsNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originController = TextEditingController(text: '上海市浦东新区陆家嘴');
  final _destController = TextEditingController();

  String _cargoType = '普通货物';
  String _vehicleType = '小面';
  String _weight = '≤100kg';
  String _volume = '≤1m³';
  String _deliveryTime = '尽快';
  bool _isPublished = false;

  static const _deliveryOptions = ['尽快', '今天', '明天', '本周内', '自定义'];

  @override
  void dispose() {
    _goodsNameController.dispose();
    _priceController.dispose();
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('发布货源'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('货物信息'),
              _buildCard(
                children: [
                  _buildTextField(label: '货物名称', controller: _goodsNameController, placeholder: '如：家电、建材、家具'),
                  const SizedBox(height: 12),
                  _buildPickerRow(label: '货物类型', value: _cargoType, options: _cargoTypes, onChanged: (v) => setState(() => _cargoType = v)),
                  const SizedBox(height: 12),
                  _buildPickerRow(label: '重量', value: _weight, options: _weightOptions, onChanged: (v) => setState(() => _weight = v)),
                  const SizedBox(height: 12),
                  _buildPickerRow(label: '体积', value: _volume, options: _volumeOptions, onChanged: (v) => setState(() => _volume = v)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('运输路线'),
              _buildCard(
                children: [
                  _buildTextField(label: '出发地', controller: _originController, placeholder: '输入始发地'),
                  const SizedBox(height: 12),
                  _buildTextField(label: '目的地', controller: _destController, placeholder: '输入目的地'),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('用车需求'),
              _buildCard(
                children: [
                  _buildPickerRow(label: '期望车型', value: _vehicleType, options: _vehicleTypes, onChanged: (v) => setState(() => _vehicleType = v)),
                  const SizedBox(height: 12),
                  _buildPickerRow(label: '发货时间', value: _deliveryTime, options: _deliveryOptions, onChanged: (v) => setState(() => _deliveryTime = v)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('运费报价'),
              _buildCard(
                children: [
                  Row(
                    children: [
                      const Text('¥ ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange)),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          placeholder: '输入期望运费',
                          placeholderStyle: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
                          style: const TextStyle(fontSize: 15),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4.withValues(alpha: 0.5))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('参考价：小面起步¥30，中面起步¥50', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CupertinoButton(
                onPressed: _isPublished ? null : _handlePublish,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                color: CupertinoColors.activeBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isPublished ? '已发布 ✓' : '立即发布',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white),
                ),
              ),
              if (_isPublished) ...[
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  color: CupertinoColors.systemGrey5,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text('返回首页', style: TextStyle(fontSize: 15, color: CupertinoColors.activeBlue)),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePublish() {
    if (_goodsNameController.text.trim().isEmpty) {
      _showToast('请填写货物名称');
      return;
    }
    if (_destController.text.trim().isEmpty) {
      _showToast('请填写目的地');
      return;
    }
    setState(() => _isPublished = true);
    _showToast('货源发布成功！等待司机报价中...');
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String placeholder, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          placeholderStyle: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          style: const TextStyle(fontSize: 14),
          keyboardType: keyboardType,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerRow({required String label, required String value, required List<String> options, required ValueChanged<String> onChanged}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isSelected = opt == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onChanged(opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? null : Border.all(color: CupertinoColors.systemGrey4),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.darkBackgroundGray,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
