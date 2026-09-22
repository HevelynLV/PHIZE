final RegExp _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validarEmail(String valor) {
  final email = valor.trim();
  if (email.isEmpty) return 'Informe seu e-mail.';
  if (!_regexEmail.hasMatch(email)) return 'E-mail inválido.';
  return null;
}

String? validarSenha(String valor) {
  if (valor.length < 8) return 'A senha deve ter no mínimo 8 caracteres.';
  return null;
}
