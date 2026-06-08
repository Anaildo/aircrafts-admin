import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/companhia.dart';
import '../models/aeronave.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<List<CompanhiaAerea>> getCompanhias() async {
    final response = await http.get(Uri.parse('$baseUrl/companhias'));
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((c) => CompanhiaAerea.fromJson(c as Map<String, dynamic>)).toList();
    }
    throw Exception('Erro ao buscar companhias (${response.statusCode})');
  }

  static Future<CompanhiaAerea> criarCompanhia(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companhias'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    if (response.statusCode == 201) {
      return CompanhiaAerea.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao criar companhia (${response.statusCode})');
  }

  static Future<void> deletarCompanhia(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/companhias/$id'));
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar companhia (${response.statusCode})');
    }
  }

  static Future<List<Aeronave>> getAeronaves(int companhiaId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/companhias/$companhiaId/aeronaves'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((a) => Aeronave.fromJson(a as Map<String, dynamic>)).toList();
    }
    throw Exception('Erro ao buscar aeronaves (${response.statusCode})');
  }

  static Future<Aeronave> adicionarAeronave(
      int companhiaId, Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companhias/$companhiaId/aeronaves'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    if (response.statusCode == 201) {
      return Aeronave.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao adicionar aeronave (${response.statusCode})');
  }

  static Future<void> deletarAeronave(int companhiaId, int aeronaveId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/companhias/$companhiaId/aeronaves/$aeronaveId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar aeronave (${response.statusCode})');
    }
  }
}
