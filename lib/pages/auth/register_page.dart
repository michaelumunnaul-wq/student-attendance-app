import 'package:flutter/material.dart';
import '../../models/admin.dart';
import '../../utils/auth_helper.dart';
import '../home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final admin = Admin(
      username: _usernameCtrl.text.trim(),
      passwordHash: AuthHelper.hashPassword(_passwordCtrl.text),
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    await AuthHelper.saveAdmin(admin);
    await AuthHelper.login(admin.fullName);

    setState(() => _loading = false);
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              Icon(Icons.school, size: 72, color: primary),
              const SizedBox(height: 16),
              Text('Teacher Registration',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Create your authorized account',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(children: [
                  _field(_fullNameCtrl, 'Full Name', Icons.person,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),
                  _field(_emailCtrl, 'Email', Icons.email,
                      type: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.contains('@') ? null : 'Enter a valid email'),
                  const SizedBox(height: 14),
                  _field(_usernameCtrl, 'Username', Icons.account_circle,
                      validator: (v) =>
                          v!.length >= 4 ? null : 'Min 4 characters'),
                  const SizedBox(height: 14),
                  _passField(_passwordCtrl, 'Password', _obscure1,
                      () => setState(() => _obscure1 = !_obscure1),
                      validator: (v) =>
                          v!.length >= 6 ? null : 'Min 6 characters'),
                  const SizedBox(height: 14),
                  _passField(_confirmCtrl, 'Confirm Password', _obscure2,
                      () => setState(() => _obscure2 = !_obscure2),
                      validator: (v) => v == _passwordCtrl.text
                          ? null
                          : 'Passwords do not match'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primary,
                          foregroundColor: Colors.white),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Register',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon)),
      validator: validator,
    );
  }

  Widget _passField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: toggle),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl,
      _emailCtrl,
      _usernameCtrl,
      _passwordCtrl,
      _confirmCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
