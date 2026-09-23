import 'marca_conhecida.dart';

/// Lista curada de marcas brasileiras frequentemente imitadas em golpes de
/// typosquatting (RF03; arquitetura, seção 4, item 4). Arquivo de
/// configuração isolado do código de comparação (`AnalisadorTyposquatting`),
/// para que a lista possa crescer sem tocar na lógica de distância de
/// edição — começa pelos 20 principais bancos e serviços financeiros do
/// Brasil. Alguns registros incluem `apelidos`: nomes curtos de uso comum
/// pelos quais a marca também é conhecida (ex.: "inter" para o Banco
/// Inter, cujo domínio oficial usa "bancointer").
const List<MarcaConhecida> marcasConhecidas = [
  MarcaConhecida(nome: 'itau', dominioOficial: 'itau.com.br'),
  MarcaConhecida(nome: 'bradesco', dominioOficial: 'bradesco.com.br'),
  MarcaConhecida(nome: 'santander', dominioOficial: 'santander.com.br'),
  MarcaConhecida(
    nome: 'caixa',
    dominioOficial: 'caixa.gov.br',
    apelidos: ['cef'],
  ),
  MarcaConhecida(nome: 'bb', dominioOficial: 'bb.com.br'),
  MarcaConhecida(nome: 'nubank', dominioOficial: 'nubank.com.br'),
  MarcaConhecida(
    nome: 'bancointer',
    dominioOficial: 'bancointer.com.br',
    apelidos: ['inter'],
  ),
  MarcaConhecida(nome: 'c6bank', dominioOficial: 'c6bank.com.br'),
  MarcaConhecida(nome: 'original', dominioOficial: 'original.com.br'),
  MarcaConhecida(nome: 'next', dominioOficial: 'next.me'),
  MarcaConhecida(nome: 'neon', dominioOficial: 'neon.com.br'),
  MarcaConhecida(nome: 'picpay', dominioOficial: 'picpay.com'),
  MarcaConhecida(nome: 'mercadopago', dominioOficial: 'mercadopago.com.br'),
  MarcaConhecida(nome: 'pagbank', dominioOficial: 'pagbank.com.br'),
  MarcaConhecida(nome: 'sicoob', dominioOficial: 'sicoob.com.br'),
  MarcaConhecida(nome: 'sicredi', dominioOficial: 'sicredi.com.br'),
  MarcaConhecida(nome: 'banrisul', dominioOficial: 'banrisul.com.br'),
  MarcaConhecida(nome: 'safra', dominioOficial: 'safra.com.br'),
  MarcaConhecida(
    nome: 'btgpactual',
    dominioOficial: 'btgpactual.com',
    apelidos: ['btg'],
  ),
  MarcaConhecida(
    nome: 'xpi',
    dominioOficial: 'xpi.com.br',
    apelidos: ['xp'],
  ),
];
