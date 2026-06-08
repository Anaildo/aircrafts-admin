import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/companhia.dart';

class FormCompanhiaDialog extends StatefulWidget {
  const FormCompanhiaDialog({super.key});

  @override
  State<FormCompanhiaDialog> createState() => _FormCompanhiaDialogState();
}

class _FormCompanhiaDialogState extends State<FormCompanhiaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _iataCtrl = TextEditingController();
  final _paisCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();

  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _iataCtrl.dispose();
    _paisCtrl.dispose();
    _anoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final nova = await ApiService.criarCompanhia({
        'nome': _nomeCtrl.text.trim(),
        'codigo_iata': _iataCtrl.text.trim().toUpperCase(),
        'pais': _paisCtrl.text.trim(),
        'ano_fundacao': int.parse(_anoCtrl.text.trim()),
      });
      if (mounted) Navigator.of(context).pop(nova);
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1929),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nova Companhia Aérea',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Campo(
                  label: 'Nome da companhia',
                  controller: _nomeCtrl,
                  hint: 'Ex: LATAM Airlines',
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                _Campo(
                  label: 'Código IATA',
                  controller: _iataCtrl,
                  hint: 'Ex: LA',
                  maxLength: 3,
                  uppercase: true,
                  validator: (v) {
                    if (v!.isEmpty) return 'Campo obrigatório';
                    if (v.length < 2) return 'Mínimo 2 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _Campo(
                  label: 'País',
                  controller: _paisCtrl,
                  hint: 'Ex: Brasil',
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                _Campo(
                  label: 'Ano de fundação',
                  controller: _anoCtrl,
                  hint: 'Ex: 1995',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Campo obrigatório';
                    final n = int.tryParse(v);
                    if (n == null || n < 1900 || n > 2100) return 'Ano inválido';
                    return null;
                  },
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Text(_erro!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Criar Companhia',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool uppercase;

  const _Campo({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization:
              uppercase ? TextCapitalization.characters : TextCapitalization.none,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF334155), fontSize: 14),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFF1A2640),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E2D40)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E2D40)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
