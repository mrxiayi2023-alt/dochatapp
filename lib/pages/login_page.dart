import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';

// ---------------------------------------------------------------------------
// Login / Register Page
// ---------------------------------------------------------------------------

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  int _segmentIndex = 0; // 0 = login, 1 = register

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  int _countdown = 0;
  Timer? _countdownTimer;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  void _onSegmentChanged(int index) {
    setState(() {
      _segmentIndex = index;
      if (index == 0) _codeController.clear();
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      _showError('请输入正确的手机号');
      return;
    }
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _countdown = 0);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.length != 11) {
      _showError('请输入正确的手机号');
      return;
    }
    if (password.length < 6) {
      _showError('密码至少6位');
      return;
    }

    if (_segmentIndex == 1) {
      // Register
      final code = _codeController.text.trim();
      if (code.length != 6) {
        _showError('请输入6位验证码');
        return;
      }
      setState(() => _loading = true);
      final error = await ref.read(authProvider.notifier).register(phone, password, code);
      if (mounted) setState(() => _loading = false);
      if (error != null) _showError(error);
      return;
    }

    // Login
    setState(() => _loading = true);
    final error = await ref.read(authProvider.notifier).login(phone, password);
    if (mounted) setState(() => _loading = false);
    if (error != null) _showError(error);
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
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

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isRegister = _segmentIndex == 1;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFF2F2F7),
        border: Border(bottom: BorderSide(color: Color(0x00000000), width: 0)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              const Icon(
                CupertinoIcons.mail_solid,
                size: 64,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(height: 12),
              const Text(
                '电邮APP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '登录以继续使用',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 32),

              // Segmented control
              CupertinoSegmentedControl<int>(
                padding: const EdgeInsets.all(2),
                groupValue: _segmentIndex,
                selectedColor: CupertinoColors.activeBlue,
                borderColor: CupertinoColors.systemGrey4,
                onValueChanged: _onSegmentChanged,
                children: {
                  0: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: const Text('登录', style: TextStyle(fontSize: 15), overflow: TextOverflow.visible),
                  ),
                  1: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: const Text('注册', style: TextStyle(fontSize: 15), overflow: TextOverflow.visible),
                  ),
                },
              ),
              const SizedBox(height: 28),

              // Phone
              _buildField(
                controller: _phoneController,
                placeholder: '手机号',
                keyboardType: TextInputType.phone,
                prefix: const Text('+86 ', style: TextStyle(fontSize: 16, color: CupertinoColors.black)),
              ),
              const SizedBox(height: 12),

              // Password
              _buildField(
                controller: _passwordController,
                placeholder: '密码',
                obscureText: true,
              ),
              const SizedBox(height: 12),

              // Code field — visible only in register mode
              if (isRegister) ...[
                _buildCodeField(),
                const SizedBox(height: 12),
              ],

              // Submit button — always shows "登录" regardless of segment
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(12),
                  pressedOpacity: 0.7,
                  onPressed: _loading ? null : _submit,
                  padding: EdgeInsets.zero,
                  child: _loading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text(
                          '登录',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Code field with send button
  // -------------------------------------------------------------------------

  Widget _buildCodeField() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildField(
            controller: _codeController,
            placeholder: '验证码',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ),
        const SizedBox(width: 10),
        // Send code button — text-only iOS style
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          pressedOpacity: 0.5,
          disabledColor: CupertinoColors.systemGrey3,
          onPressed: _countdown > 0 || _loading ? null : _sendCode,
          child: Text(
            _countdown > 0 ? '${_countdown}s 后重发' : '发送验证码',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _countdown > 0 ? CupertinoColors.systemGrey : CupertinoColors.activeBlue,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Generic field builder
  // -------------------------------------------------------------------------

  Widget _buildField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefix,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(
          fontSize: 16,
          color: CupertinoColors.systemGrey3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
        obscureText: obscureText,
        keyboardType: keyboardType ?? TextInputType.text,
        maxLength: maxLength,
        prefix: prefix,
        clearButtonMode: OverlayVisibilityMode.editing,
      ),
    );
  }
}
