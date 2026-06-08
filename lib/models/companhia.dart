import 'aeronave.dart';

class CompanhiaAerea {
  final int id;
  final String nome;
  final String codigoIata;
  final String pais;
  final int anoFundacao;
  final List<Aeronave> frota;

  const CompanhiaAerea({
    required this.id,
    required this.nome,
    required this.codigoIata,
    required this.pais,
    required this.anoFundacao,
    this.frota = const [],
  });

  factory CompanhiaAerea.fromJson(Map<String, dynamic> json) {
    return CompanhiaAerea(
      id: json['id'] as int,
      nome: json['nome'] as String,
      codigoIata: json['codigo_iata'] as String,
      pais: json['pais'] as String,
      anoFundacao: json['ano_fundacao'] as int,
      frota: (json['frota'] as List<dynamic>? ?? [])
          .map((a) => Aeronave.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'codigo_iata': codigoIata,
        'pais': pais,
        'ano_fundacao': anoFundacao,
      };

  int get totalPassageiros => frota.where((a) => a.isPassageiros).length;
  int get totalCarga => frota.where((a) => a.isCarga).length;
}
