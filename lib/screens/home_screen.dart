import 'dart:async';
import 'package:flutter/material.dart';
import '../models/companhia.dart';
import '../services/api_service.dart';
import '../services/broker_service.dart';
import 'formularios/form_companhia.dart';
import 'frota_screen.dart';









class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CompanhiaAerea> _companhias = [];
  bool _loading = true;
  String _busca = '';
  StreamSubscription? _sseSub;

  @override
  void initState() {
    super.initState();
    _carregarCompanhias();
    _iniciarSSE();
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarCompanhias() async {
    setState(() => _loading = true);
    try {
      final lista = await ApiService.getCompanhias();
      setState(() {
        _companhias = lista;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        _mostrarErro('Não foi possível conectar à API.\n$e');
      }
    }
  }

  void _iniciarSSE() {
    _sseSub = BrokerService.ouvirEventos().listen((evento) {
      
      final tipo = evento['tipo'] as String? ?? '';
      if (tipo.contains('COMPANHIA') || tipo.contains('AERONAVE')) {
        _carregarCompanhias();
        if (mounted) _mostrarEvento(evento);
      }
    });
  }

  void _mostrarEvento(Map<String, dynamic> evento) {
    final tipo = evento['tipo'] as String? ?? '';
    final dados = evento['dados'] as Map<String, dynamic>? ?? {};
    String msg = switch (tipo) {
      'COMPANHIA_CRIADA' => '✈ Companhia "${dados['nome']}" criada',
      'COMPANHIA_REMOVIDA' => '🗑 Companhia removida',
      'AERONAVE_ADICIONADA' =>
        '➕ Aeronave ${dados['prefixo']} adicionada',
      'AERONAVE_REMOVIDA' => '➖ Aeronave removida da frota',
      _ => tipo,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF00D4FF).withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _abrirFormCompanhia() async {
    final nova = await showDialog<CompanhiaAerea>(
      context: context,
      builder: (_) => const FormCompanhiaDialog(),
    );
    if (nova != null) _carregarCompanhias();
  }

  Future<void> _deletarCompanhia(CompanhiaAerea c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1929),
        title: const Text('Confirmar exclusão',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja remover "${c.nome}" e toda sua frota?\nEssa ação não pode ser desfeita.',
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
        await ApiService.deletarCompanhia(c.id);
        _carregarCompanhias();
      } catch (e) {
        if (mounted) _mostrarErro(e.toString());
      }
    }
  }

  List<CompanhiaAerea> get _companhiasFiltradas {
    if (_busca.isEmpty) return _companhias;
    final q = _busca.toLowerCase();
    return _companhias.where((c) {
      return c.nome.toLowerCase().contains(q) ||
          c.codigoIata.toLowerCase().contains(q) ||
          c.pais.toLowerCase().contains(q);
    }).toList();
  }

  

  int get _totalAeronaves =>
      _companhias.fold(0, (sum, c) => sum + c.frota.length);
  int get _totalPassageiros =>
      _companhias.fold(0, (sum, c) => sum + c.totalPassageiros);
  int get _totalCarga =>
      _companhias.fold(0, (sum, c) => sum + c.totalCarga);

  

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
                        _buildHero(),
                        const SizedBox(height: 32),
                        _buildStats(),
                        const SizedBox(height: 32),
                        _buildMainContent(),
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
        onPressed: _abrirFormCompanhia,
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nova Companhia',
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
                  border: Border.all(color: const Color(0xFF00D4FF), width: 1.5),
                ),
                child: const Icon(Icons.flight, color: Color(0xFF00D4FF), size: 16),
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
          const SizedBox(width: 32),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
            ),
            child: const Text(
              'Dashboard',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          
          _StatusBadge(live: _companhias.isNotEmpty || !_loading),
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

  

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AIRCRAFT API // DASHBOARD',
          style: TextStyle(
            color: const Color(0xFF00D4FF).withOpacity(0.7),
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fleet Intelligence',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const Text(
          'Monitor',
          style: TextStyle(
            color: Color(0xFF00D4FF),
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Monitoramento em tempo real das frotas aéreas brasileiras',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }

  

  Widget _buildStats() {
    final isWide = MediaQuery.of(context).size.width > 768;
    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.flight,
              label: 'AERONAVES',
              value: '$_totalAeronaves',
              sublabel: 'em base de dados',
              color: const Color(0xFF00D4FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              icon: Icons.people_outline,
              label: 'PASSAGEIROS',
              value: '$_totalPassageiros',
              sublabel: 'aeronaves PAX',
              color: const Color(0xFF818CF8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              icon: Icons.inventory_2_outlined,
              label: 'CARGA',
              value: '$_totalCarga',
              sublabel: 'aeronaves cargo',
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatCard(
            icon: Icons.flight,
            label: 'AERONAVES',
            value: '$_totalAeronaves',
            sublabel: 'em base de dados',
            color: const Color(0xFF00D4FF),
          ),
          const SizedBox(height: 16),
          _StatCard(
            icon: Icons.people_outline,
            label: 'PASSAGEIROS',
            value: '$_totalPassageiros',
            sublabel: 'aeronaves PAX',
            color: const Color(0xFF818CF8),
          ),
          const SizedBox(height: 16),
          _StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'CARGA',
            value: '$_totalCarga',
            sublabel: 'aeronaves cargo',
            color: const Color(0xFFF59E0B),
          ),
        ],
      );
    }
  }

  

  Widget _buildMainContent() {
    final isWide = MediaQuery.of(context).size.width > 992;
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Expanded(
            flex: 6,
            child: _buildCompanhiasList(),
          ),
          const SizedBox(width: 24),
          
          SizedBox(
            width: 360,
            child: Column(
              children: [
                _buildBarChart(),
                const SizedBox(height: 16),
                _buildEndpointsPanel(),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompanhiasList(),
          const SizedBox(height: 24),
          _buildBarChart(),
          const SizedBox(height: 16),
          _buildEndpointsPanel(),
        ],
      );
    }
  }

  

  Widget _buildCompanhiasList() {
    final filtradas = _companhiasFiltradas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _busca = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar companhia por nome, IATA...',
                  hintStyle: const TextStyle(color: Color(0xFF334155)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF475569), size: 20),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1929),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E2D40)),
              ),
              child: Text(
                '${filtradas.length}/${_companhias.length}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            
            IconButton(
              onPressed: _carregarCompanhias,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF00D4FF)),
                    )
                  : const Icon(Icons.refresh, color: Color(0xFF475569), size: 20),
              tooltip: 'Atualizar',
            ),
          ],
        ),
        const SizedBox(height: 16),

        
        if (_loading && _companhias.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
            ),
          )
        else if (filtradas.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1929),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2D40)),
            ),
            child: Column(
              children: [
                Icon(Icons.flight_land,
                    color: const Color(0xFF1E2D40), size: 48),
                const SizedBox(height: 16),
                Text(
                  _busca.isEmpty
                      ? 'Nenhuma companhia cadastrada'
                      : 'Nenhum resultado para "$_busca"',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...filtradas.map((c) => _CompanhiaCard(
                companhia: c,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FrotaScreen(companhia: c),
                    ),
                  ).then((_) => _carregarCompanhias());
                },
                onDelete: () => _deletarCompanhia(c),
              )),
      ],
    );
  }

  

  Widget _buildBarChart() {
    final maxFrota = _companhias.isEmpty
        ? 1
        : _companhias.map((c) => c.frota.length).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1929),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FROTA POR COMPANHIA',
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: 11,
                  letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (_companhias.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sem dados', style: TextStyle(color: Color(0xFF334155))),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _companhias.map((c) {
                  final height = maxFrota == 0
                      ? 4.0
                      : (c.frota.length / maxFrota) * 80.0 + 4;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${c.frota.length}',
                              style: const TextStyle(
                                  color: Color(0xFF00D4FF), fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF).withOpacity(0.6),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(c.codigoIata,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  

  Widget _buildEndpointsPanel() {
    const endpoints = [
      ('GET', '/companhias'),
      ('GET', '/companhias/{iata}'),
      ('GET', '/aeronaves'),
      ('GET', '/aeronaves/{prefixo}'),
      ('POST', '/companhias'),
      ('POST', '/aeronaves'),
      ('DELETE', '/companhias/{id}'),
      ('GET', '/eventos/stream'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1929),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ENDPOINTS DISPONÍVEIS',
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: 11,
                  letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...endpoints.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 3),
                      decoration: BoxDecoration(
                        color: e.$1 == 'GET'
                            ? const Color(0xFF00D4FF).withOpacity(0.15)
                            : e.$1 == 'POST'
                                ? const Color(0xFFF59E0B).withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: e.$1 == 'GET'
                              ? const Color(0xFF00D4FF)
                              : e.$1 == 'POST'
                                  ? const Color(0xFFF59E0B)
                                  : Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.$2,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12,
                            fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}



class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1929),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11,
                        letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(value,
                    style: TextStyle(
                        color: color, fontSize: 32,
                        fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(height: 4),
                Text(sublabel,
                    style: const TextStyle(
                        color: Color(0xFF475569), fontSize: 12)),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.4), size: 32),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool live;
  const _StatusBadge({required this.live});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
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
          Text(
            live ? 'API LIVE' : 'OFFLINE',
            style: TextStyle(
              color: live ? const Color(0xFF10B981) : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanhiaCard extends StatefulWidget {
  final CompanhiaAerea companhia;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CompanhiaCard({
    required this.companhia,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_CompanhiaCard> createState() => _CompanhiaCardState();
}

class _CompanhiaCardState extends State<_CompanhiaCard> {
  bool _hover = false;

  Color _iataColor(String iata) {
    final colors = [
      const Color(0xFF0E4D64),
      const Color(0xFF1E3A5F),
      const Color(0xFF3D2B5C),
      const Color(0xFF1B4A2E),
      const Color(0xFF4A2B1B),
      const Color(0xFF2B1B4A),
    ];
    int hash = 0;
    for (final c in iata.codeUnits) {
      hash = (hash * 31 + c) % colors.length;
    }
    return colors[hash];
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.companhia;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hover ? const Color(0xFF141F2E) : const Color(0xFF0F1929),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hover
                    ? const Color(0xFF00D4FF).withOpacity(0.3)
                    : const Color(0xFF1E2D40),
              ),
            ),
            child: Row(
              children: [
                
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iataColor(c.codigoIata),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      c.codigoIata.substring(0, 2),
                      style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nome.toLowerCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public,
                                  color: Color(0xFF475569), size: 12),
                              const SizedBox(width: 4),
                              Text(c.pais,
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF475569), size: 12),
                              const SizedBox(width: 4),
                              Text('Est. ${c.anoFundacao}',
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${c.frota.length}',
                        style: const TextStyle(
                            color: Color(0xFF00D4FF), fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const Text('aeronaves',
                        style: TextStyle(
                            color: Color(0xFF475569), fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 12),
                
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFF334155), size: 18),
                  tooltip: 'Remover companhia',
                ),
                
                const Icon(Icons.chevron_right,
                    color: Color(0xFF334155), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
