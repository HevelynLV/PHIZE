import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/seletor_imagem_galeria.dart';

/// Só a regra de caminho é testável sem Android: a seleção e a remoção
/// reais exigem dispositivo (ver documentação de SeletorImagemGaleria).
/// Nenhum teste aqui toca o sistema de arquivos — a regra opera sobre texto.
void main() {
  bool android(String caminho) =>
      SeletorImagemGaleria.ehCopiaTemporariaDoSeletor(caminho, android: true);
  bool ios(String caminho) =>
      SeletorImagemGaleria.ehCopiaTemporariaDoSeletor(caminho, android: false);

  group('Android: só remove a cópia em <cache>/<uuid>/', () {
    test('cópia do image_picker é reconhecida', () {
      expect(
        android(
          '/data/user/0/com.phize.app/cache/'
          '3f1c9a2e-0000-4000-8000-000000000000/print.png',
        ),
        isTrue,
      );
    });

    test('original da galeria nunca é apagado', () {
      for (final caminho in [
        '/storage/emulated/0/DCIM/Camera/IMG_0001.jpg',
        '/storage/emulated/0/Pictures/Screenshots/print.png',
        '/data/user/0/com.phize.app/cache/print.png',
        '/data/user/0/com.phize.app/cache/../files/dados.png',
        'print.png',
      ]) {
        expect(android(caminho), isFalse, reason: caminho);
      }
    });
  });

  group('iOS: só remove a cópia em tmp/', () {
    test('cópia do image_picker é reconhecida', () {
      expect(
        ios('/private/var/mobile/Containers/Data/Application/X/tmp/'
            'image_picker_ABC.jpg'),
        isTrue,
      );
    });

    test('outros caminhos não são apagados', () {
      expect(ios('/var/mobile/Media/DCIM/100APPLE/IMG_0001.JPG'), isFalse);
    });
  });
}
