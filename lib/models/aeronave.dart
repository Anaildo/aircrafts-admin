class Aeronave {
  final int id;
  final String prefixo;
  final String modelo;
  final String fabricante;
  final int anoFabricacao;
  final double autonomiaKm;
  final String tipo;
  final bool pilotoAutomaticoAtivo;
  final int companhiaId;
  final int? numAssentos;
  final String? classesDisponiveis;
  final int? tripulacaoMinima;
  final double? capacidadeCargaKg;
  final String? tipoMercadoria;
  final bool? temperaturaControlada;

  const Aeronave({
    required this.id,
    required this.prefixo,
    required this.modelo,
    required this.fabricante,
    required this.anoFabricacao,
    required this.autonomiaKm,
    required this.tipo,
    required this.pilotoAutomaticoAtivo,
    required this.companhiaId,
    this.numAssentos,
    this.classesDisponiveis,
    this.tripulacaoMinima,
    this.capacidadeCargaKg,
    this.tipoMercadoria,
    this.temperaturaControlada,
  });

  factory Aeronave.fromJson(Map<String, dynamic> json) {
    return Aeronave(
      id: json['id'] as int,
      prefixo: json['prefixo'] as String,
      modelo: json['modelo'] as String,
      fabricante: json['fabricante'] as String,
      anoFabricacao: json['ano_fabricacao'] as int,
      autonomiaKm: (json['autonomia_km'] as num).toDouble(),
      tipo: json['tipo'] as String,
      pilotoAutomaticoAtivo: json['piloto_automatico_ativo'] as bool? ?? false,
      companhiaId: json['companhia_id'] as int,
      numAssentos: json['num_assentos'] as int?,
      classesDisponiveis: json['classes_disponiveis'] as String?,
      tripulacaoMinima: json['tripulacao_minima'] as int?,
      capacidadeCargaKg: (json['capacidade_carga_kg'] as num?)?.toDouble(),
      tipoMercadoria: json['tipo_mercadoria'] as String?,
      temperaturaControlada: json['temperatura_controlada'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'prefixo': prefixo,
      'modelo': modelo,
      'fabricante': fabricante,
      'ano_fabricacao': anoFabricacao,
      'autonomia_km': autonomiaKm,
      'tipo': tipo,
      'piloto_automatico_ativo': pilotoAutomaticoAtivo,
    };
    if (numAssentos != null) map['num_assentos'] = numAssentos;
    if (classesDisponiveis != null) map['classes_disponiveis'] = classesDisponiveis;
    if (tripulacaoMinima != null) map['tripulacao_minima'] = tripulacaoMinima;
    if (capacidadeCargaKg != null) map['capacidade_carga_kg'] = capacidadeCargaKg;
    if (tipoMercadoria != null) map['tipo_mercadoria'] = tipoMercadoria;
    if (temperaturaControlada != null) map['temperatura_controlada'] = temperaturaControlada;
    return map;
  }

  bool get isPassageiros => tipo.toLowerCase() == 'passageiros';
  bool get isCarga => tipo.toLowerCase() == 'carga';
  String get tipoDisplay => isPassageiros ? 'PAX' : 'CARGO';
  int get capacidade =>
      isPassageiros ? (numAssentos ?? 0) : (capacidadeCargaKg?.toInt() ?? 0);
}
