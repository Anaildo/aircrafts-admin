import 'dart:async';
import 'package:flutter/material.dart';
import '../models/aeronave.dart';
import '../models/companhia.dart';
import '../services/api_service.dart';
import '../services/broker_service.dart';
import 'formularios/form_aeronave.dart';








class FrotaScreen extends StatefulWidget {
  final CompanhiaAerea companhia;

  const FrotaScreen({super.key, required this.companhia});

  @override
  State<FrotaScreen> createState() => _FrotaScreenState();
}

class _FrotaScreenState extends State<FrotaScreen> {
  List<Aeronave> _aeronaves = [];
  bool _loading = true;
  String _filtro = 'todos'; 
  String _busca = '';
  StreamSubscription? _sseSub;

  @override
  void initState() {
    super.initState();
    _carregarAeronaves();
    _iniciarSSE();
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarAeronaves() async {
    setState(() => _loading = true);
    try {
      final lista = await ApiService.getAeronaves(widget.companhia.id);
      setState(() {
        _aeronaves = lista;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _mostrarErro(e.toString());
    }
  }

  void _iniciarSSE() {
    _sseSub = BrokerService.ouvirEventos().listen((evento) {
      final tipo = evento['tipo'] as String? ?? '';
      final dados = evento['dados'] as Map<String, dynamic>? ?? {};

      
      final companhiaEvento = dados['companhia_id'];
      if (companhiaEvento != null &&
          companhiaEvento != widget.companhia.id) return;

      if (tipo == 'AERONAVE_ADICIONADA' || tipo == 'AERONAVE_REMOVIDA') {
        _carregarAeronaves();
        if (mounted) _mostrarNotificacao(tipo, dados);
      }
    });
  }

  void _mostrarNotificacao(String tipo, Map<String, dynamic> dados) {
    final msg = tipo == 'AERONAVE_ADICIONADA'
        ? '➕ Aeronave ${dados['prefixo'] ?? ''} adicionada à frota'
        : '➖ Aeronave removida da frota';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF00D4FF).withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.replaceAll('Exception: ', '')),
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _abrirFormAeronave() async {
    final nova = await showDialog<Aeronave>(
      context: context,
      builder: (_) => FormAeronaveDialog(companhiaId: widget.companhia.id),
    );
    if (nova != null) _carregarAeronaves();
  }

  Future<void> _deletarAeronave(Aeronave a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1929),
        title: const Text('Confirmar remoção',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remover aeronave ${a.prefixo} (${a.modelo})?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF64748B)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remover',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deletarAeronave(widget.companhia.id, a.id);
        _carregarAeronaves();
      } catch (e) {
        if (mounted) _mostrarErro(e.toString());
      }
    }
  }

  List<Aeronave> get _aeronavesFiltradas {
    var lista = _aeronaves;
    if (_filtro == 'passageiros') {
      lista = lista.where((a) => a.isPassageiros).toList();
    } else if (_filtro == 'carga') {
      lista = lista.where((a) => a.isCarga).toList();
    }
    if (_busca.isNotEmpty) {
      final q = _busca.toLowerCase();
      lista = lista.where((a) =>
          a.prefixo.toLowerCase().contains(q) ||
          a.modelo.toLowerCase().contains(q) ||
          a.fabricante.toLowerCase().contains(q)).toList();
    }
    return lista;
  }

  int get _totalPassageiros => _aeronaves.where((a) => a.isPassageiros).length;
  int get _totalCarga => _aeronaves.where((a) => a.isCarga).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompanhiaHero(),
                        const SizedBox(height: 24),
                        _buildFiltros(),
                        const SizedBox(height: 16),
                        _buildTabela(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormAeronave,
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Aeronave',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  

  Widget _buildTopBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF080D1A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D40))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: const Color(0xFF00D4FF), width: 1.5),
                ),
                child: const Icon(Icons.flight,
                    color: Color(0xFF00D4FF), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'AIRCRAFTAPI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 14,
                color: Color(0xFF64748B)),
            label: const Text('Voltar ao Dashboard',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          const Spacer(),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('API LIVE',
                    style: TextStyle(
                        color: Color(0xFF10B981), fontSize: 11,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2640),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF1E2D40)),
            ),
            child: const Text('v3.0',
                style: TextStyle(
                    color: Color(0xFF64748B), fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  

  Widget _buildCompanhiaHero() {
    final c = widget.companhia;

    Color badgeColor(String iata) {
      final colors = [
        const Color(0xFF0E4D64),
        const Color(0xFF1E3A5F),
        const Color(0xFF3D2B5C),
        const Color(0xFF1B4A2E),
        const Color(0xFF4A2B1B),
        const Color(0xFF2B1B4A),
      ];
      int hash = 0;
      for (final ch in iata.codeUnits) hash = (hash * 31 + ch) % colors.length;
      return colors[hash];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1929),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Row(
        children: [
          
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: badgeColor(c.codigoIata),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                c.codigoIata.length >= 2
                    ? c.codigoIata.substring(0, 2)
                    : c.codigoIata,
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nome,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    _MetaChip(icon: Icons.tag, label: 'ID: ${c.codigoIata}'),
                    _MetaChip(icon: Icons.public, label: c.pais),
                    _MetaChip(
                        icon: Icons.calendar_today,
                        label: 'Est. ${c.anoFundacao}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Companhia aérea operando em ${c.pais}. Fundada em ${c.anoFundacao}.',
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2640),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2D40)),
            ),
            child: Column(
              children: [
                Text(
                  '${_aeronaves.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('TOTAL FROTA',
                    style: TextStyle(
                        color: Color(0xFF64748B), fontSize: 10,
                        letterSpacing: 1.2, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Row(
          children: [
            _StatChip(
              icon: Icons.people_outline,
              label: '$_totalPassageiros PASSAGEIROS',
              color: const Color(0xFF00D4FF),
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.inventory_2_outlined,
              label: '$_totalCarga CARGA',
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _busca = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por prefixo ou modelo...',
                  hintStyle: const TextStyle(color: Color(0xFF334155)),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF475569), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF0F1929),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _FiltroBotao(
              label: 'TODOS',
              selected: _filtro == 'todos',
              onTap: () => setState(() => _filtro = 'todos'),
            ),
            const SizedBox(width: 6),
            _FiltroBotao(
              label: 'PAX',
              selected: _filtro == 'passageiros',
              color: const Color(0xFF00D4FF),
              onTap: () => setState(() => _filtro = 'passageiros'),
            ),
            const SizedBox(width: 6),
            _FiltroBotao(
              label: 'CARGO',
              selected: _filtro == 'carga',
              color: const Color(0xFFF59E0B),
              onTap: () => setState(() => _filtro = 'carga'),
            ),
          ],
        ),
      ],
    );
  }

  

  Widget _buildTabela() {
    final lista = _aeronavesFiltradas;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1929),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
              ),
            )
          else if (lista.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.flight_land,
                        color: const Color(0xFF1E2D40), size: 48),
                    const SizedBox(height: 16),
                    const Text('Nenhuma aeronave encontrada',
                        style: TextStyle(
                            color: Color(0xFF475569), fontSize: 14)),
                  ],
                ),
              ),
            )
          else ...[
            
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFF1E2D40))),
              ),
              child: const Row(
                children: [
                  _CabecalhoCol(label: 'PREFIXO', flex: 2),
                  _CabecalhoCol(label: 'MODELO', flex: 3),
                  _CabecalhoCol(label: 'TIPO', flex: 1),
                  _CabecalhoCol(label: 'CAPACIDADE', flex: 2),
                  _CabecalhoCol(label: 'ANO', flex: 1),
                  SizedBox(width: 48),
                ],
              ),
            ),
            
            ...lista.map((a) => _AeronaveRow(
                  aeronave: a,
                  onDelete: () => _deletarAeronave(a),
                )),
            
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E2D40))),
              ),
              child: Text(
                '${lista.length} aeronave${lista.length != 1 ? 's' : ''} exibida${lista.length != 1 ? 's' : ''}. '
                'Clique em ✕ para remover.',
                style: const TextStyle(
                    color: Color(0xFF475569), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF475569), size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FiltroBotao extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FiltroBotao({
    required this.label,
    required this.selected,
    this.color = const Color(0xFF94A3B8),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFF0F1929),
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
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CabecalhoCol extends StatelessWidget {
  final String label;
  final int flex;

  const _CabecalhoCol({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AeronaveRow extends StatefulWidget {
  final Aeronave aeronave;
  final VoidCallback onDelete;

  const _AeronaveRow({required this.aeronave, required this.onDelete});

  @override
  State<_AeronaveRow> createState() => _AeronaveRowState();
}

class _AeronaveRowState extends State<_AeronaveRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.aeronave;
    final isPax = a.isPassageiros;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hover
            ? const Color(0xFF141F2E)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            
            Expanded(
              flex: 2,
              child: Text(
                a.prefixo,
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            Expanded(
              flex: 3,
              child: Text(
                a.modelo,
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
              ),
            ),
            
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPax
                      ? const Color(0xFF00D4FF).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPax
                        ? const Color(0xFF00D4FF).withOpacity(0.3)
                        : const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPax ? Icons.people : Icons.inventory_2,
                      size: 10,
                      color: isPax
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      a.tipoDisplay,
                      style: TextStyle(
                        color: isPax
                            ? const Color(0xFF00D4FF)
                            : const Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              flex: 2,
              child: Text(
                a.capacidade > 0 ? '${a.capacidade}' : '—',
                style: const TextStyle(
                    color: Color(0xFFE2E8F0), fontSize: 14),
              ),
            ),
            
            Expanded(
              flex: 1,
              child: Text(
                '${a.anoFabricacao}',
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
            
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: _hover ? Colors.red : const Color(0xFF334155),
                ),
                tooltip: 'Remover aeronave',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
