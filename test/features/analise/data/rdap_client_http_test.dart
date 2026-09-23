import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/rdap_client_http.dart';

void main() {
  group('construirUriConsulta', () {
    test('domínio .br usa o RDAP do Registro.br', () {
      final uri = construirUriConsulta('itau.com.br');
      expect(uri.toString(), 'https://rdap.registro.br/domain/itau.com.br');
    });

    test('domínio genérico usa o bootstrap RDAP público', () {
      final uri = construirUriConsulta('example.com');
      expect(uri.toString(), 'https://rdap.org/domain/example.com');
    });

    test('subdomínio .br também usa o Registro.br', () {
      final uri = construirUriConsulta('sub.exemplo.com.br');
      expect(
        uri.toString(),
        'https://rdap.registro.br/domain/sub.exemplo.com.br',
      );
    });

    test('determinismo: mesma entrada produz sempre a mesma URI', () {
      expect(
        construirUriConsulta('itau.com.br').toString(),
        construirUriConsulta('itau.com.br').toString(),
      );
    });
  });
}
