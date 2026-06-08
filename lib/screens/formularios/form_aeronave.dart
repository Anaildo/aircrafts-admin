import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/aeronave.dart';

class FormAeronaveDialog extends StatefulWidget {
  final int companhiaId;

  const FormAeronaveDialog({super.key, required this.companhiaId});

  @override
  State<FormAeronaveDialog> createState() => _FormAeronaveDialogState();
}

class _FormAeronaveDialogState extends State<FormAeronaveDialog> {
  final _formKey = GlobalKey<FormState>();

  final _prefixoCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _fabricanteCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _autonomiaCtrl = TextEditingController();
  final _assentosCtrl = TextEditingController();
  final _classesCtrl = TextEditingController();
  final _tripulacaoCtrl = TextEditingController();
  final _cargaKgCtrl = TextEditingController();
  final _mercadoriaCtrl = TextEditingController();

  String _tipo = 'passageiros';
  bool _pilotoAuto = false;
  bool _temperaturaControlada = false;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _prefixoCtrl.dispose();
    _modeloCtrl.dispose();
    _fabricanteCtrl.dispose();
    _anoCtrl.dispose();
    _autonomiaCtrl.dispose();
    _assentosCtrl.dispose();
    _classesCtrl.dispose();
    _tripulacaoCtrl.dispose();
    _cargaKgCtrl.dispose();
    _mercadoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final dados = <String, dynamic>{
        'prefixo': _prefixoCtrl.text.trim().toUpperCase(),
        'modelo': _modeloCtrl.text.trim(),
        'fabricante': _fabricanteCtrl.text.trim(),
        'ano_fabricacao': int.parse(_anoCtrl.text.trim()),
        'autonomia_km': double.parse(_autonomiaCtrl.text.trim()),
        'tipo': _tipo,
        'piloto_automatico_ativo': _pilotoAuto,
      };

      if (_tipo == 'passageiros') {
        dados['num_assentos'] = int.parse(_assentosCtrl.text.trim());
        if (_classesCtrl.text.isNotEmpty) {
          dados['classes_disponiveis'] = _classesCtrl.text.trim();
        }
        if (_tripulacaoCtrl.text.isNotEmpty) {
          dados['tripulacao_minima'] = int.parse(_tripulacaoCtrl.text.trim());
        }
      } else {
        dados['capacidade_carga_kg'] = double.parse(_cargaKgCtrl.text.trim());
        if (_mercadoriaCtrl.text.isNotEmpty) {
          dados['tipo_mercadoria'] = _mercadoriaCtrl.text.trim();
        }
        dados['temperatura_controlada'] = _temperaturaControlada;
      }

      final nova = await ApiService.adicionarAeronave(widget.companhiaId, dados);
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
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
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
                      'Adicionar Aeronave',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preencha os dados da aeronave. Os campos variam conforme o tipo.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Dados gerais'),
                const SizedBox(height: 12),
                _Campo(
                  label: 'Prefixo (matrícula)',
                  hint: 'Ex: PR-GXA',
                  controller: _prefixoCtrl,
                  uppercase: true,
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Campo(
                        label: 'Modelo',
                        hint: 'Ex: Boeing 737-800',
                        controller: _modeloCtrl,
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Campo(
                        label: 'Fabricante',
                        hint: 'Ex: Boeing',
                        controller: _fabricanteCtrl,
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Campo(
                        label: 'Ano de fabricação',
                        hint: 'Ex: 2019',
                        controller: _anoCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Campo obrigatório';
                          final n = int.tryParse(v);
                          if (n == null || n < 1900 || n > 2100) return 'Ano inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Campo(
                        label: 'Autonomia (km)',
                        hint: 'Ex: 5500',
                        controller: _autonomiaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v!.isEmpty) return 'Campo obrigatório';
                          if (double.tryParse(v) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tipo',
                    style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TipoBadge(
                      label: 'Passageiros',
                      selected: _tipo == 'passageiros',
                      color: const Color(0xFF00D4FF),
                      onTap: () => setState(() => _tipo = 'passageiros'),
                    ),
                    const SizedBox(width: 8),
                    _TipoBadge(
                      label: 'Carga',
                      selected: _tipo == 'carga',
                      color: const Color(0xFFF59E0B),
                      onTap: () => setState(() => _tipo = 'carga'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: _pilotoAuto,
                      onChanged: (v) => setState(() => _pilotoAuto = v),
                      activeColor: const Color(0xFF00D4FF),
                    ),
                    const Text('Piloto automático ativo',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 20),
                if (_tipo == 'passageiros') ...[
                  _SectionLabel('Configuração de passageiros'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Campo(
                          label: 'Nº de assentos',
                          hint: 'Ex: 180',
                          controller: _assentosCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Campo obrigatório';
                            if (int.tryParse(v) == null) return 'Número inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Campo(
                          label: 'Tripulação mínima',
                          hint: 'Ex: 6',
                          controller: _tripulacaoCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Campo(
                    label: 'Classes disponíveis',
                    hint: 'Ex: Econômica, Executiva',
                    controller: _classesCtrl,
                  ),
                ] else ...[
                  _SectionLabel('Configuração de carga'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Campo(
                          label: 'Capacidade de carga (kg)',
                          hint: 'Ex: 20000',
                          controller: _cargaKgCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v!.isEmpty) return 'Campo obrigatório';
                            if (double.tryParse(v) == null) return 'Número inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Campo(
                          label: 'Tipo de mercadoria',
                          hint: 'Ex: Geral, Perecíveis',
                          controller: _mercadoriaCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: _temperaturaControlada,
                        onChanged: (v) => setState(() => _temperaturaControlada = v),
                        activeColor: const Color(0xFFF59E0B),
                      ),
                      const Text('Temperatura controlada',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                ],
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
                          : const Text('Adicionar Aeronave',
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF1E2D40))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF1E2D40))),
      ],
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TipoBadge({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFF1A2640),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFF1E2D40),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : const Color(0xFF64748B),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
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
  final bool uppercase;

  const _Campo({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
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
          textCapitalization:
              uppercase ? TextCapitalization.characters : TextCapitalization.none,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF334155), fontSize: 14),
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
