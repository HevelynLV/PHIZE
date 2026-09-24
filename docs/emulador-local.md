# Emulador local das Cloud Functions

Nesta fase a camada intermediária (arquitetura, seção 2 — Proteção de Credenciais) roda **apenas no emulador local do Firebase**, sem deploy. A decisão e suas consequências estão na Fase 5 de `docs/ROADMAP.md`.

## O que existe

| Item | Onde |
| --- | --- |
| Código da Function (TypeScript) | `functions/src/` |
| Configuração do emulador | `firebase.json` (seção `emulators`) |
| Projeto Firebase padrão | `.firebaserc` |
| Endereço que o app chama | `lib/core/config/proxy_config.dart` |

Function disponível: `reputacaoDominio` (Google Safe Browsing), na região `southamerica-east1`.

## Pré-requisitos (uma vez só)

**[TERMINAL]**, na raiz do projeto:
```
npm --prefix functions install
```

## Configurar a chave do Safe Browsing localmente

A chave **nunca** vai para o código nem para o repositório. Ela fica em um arquivo local, lido pelo emulador como variável de ambiente.

1. **[WINDOWS]** Gere a chave no Google Cloud Console: *APIs e serviços → Biblioteca → Safe Browsing API → Ativar*, depois *Credenciais → Criar credenciais → Chave de API*. A chave é gratuita e **não** depende do plano Blaze. Restrinja a chave à Safe Browsing API.

2. **[WINDOWS]** Crie o arquivo `functions/.env.local` com uma única linha:
   ```
   SAFE_BROWSING_API_KEY=<cole a chave aqui>
   ```

3. **[TERMINAL]** Confirme que o Git ignora o arquivo (a saída deve citar a regra do `.gitignore`):
   ```
   git check-ignore -v functions/.env.local
   ```

Nunca cole a chave em prompt, commit, issue, print de tela ou mensagem de grupo. Se isso acontecer, apague a chave no console e gere outra.

Sem o arquivo, a Function continua funcionando: toda consulta responde "verificação não concluída" (motivo `chave_ausente`), e o app segue com os demais sinais (degradação controlada).

## Rodar o emulador

**[TERMINAL]**, na raiz do projeto:
```
npm --prefix functions run build
```
```
firebase emulators:start --only functions
```

Quando aparecer `All emulators ready`, a Function responde em:
```
http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio
```
e o painel do emulador fica em `http://127.0.0.1:4000`. `Ctrl+C` encerra.

Em outro terminal, rode o app normalmente (`flutter run -d chrome`). O endereço padrão do app já aponta para o emulador.

> **Para testar o app, suba o emulador apenas com `--only functions`.** Com o emulador de Auth ativo (`--only functions,auth`, usado só no teste ponta a ponta descrito abaixo), o app logado no Firebase real recebe `401` na chamada à Function, e a reputação aparece como "verificação não concluída".

Avisos esperados na inicialização, que podem ser ignorados:
- *"The following emulators are not running..."* — com `--only functions`, Auth e Firestore não são emulados. Os tokens do login real são verificados normalmente pela Function.
- *"requested node version 22 doesn't match your global version"* — o emulador usa o Node instalado na máquina.

Para recompilar automaticamente enquanto edita o TypeScript, deixe rodando em outro terminal:
```
npm --prefix functions run build:watch
```

## Testes da Function

**[TERMINAL]**
```
npm --prefix functions test
```
Os testes simulam o Safe Browsing e não acessam a rede.

## Verificação rápida sem o app

Sem token, a Function deve recusar a chamada com `401`:
```
curl -X POST -H "Content-Type: application/json" -d "{\"url\":\"https://exemplo.com.br/\"}" http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio
```

## Teste ponta a ponta com o emulador de Auth

Para testar a Function com um usuário autenticado sem tocar na produção, o `firebase.json` também configura o emulador de Auth (porta `9099`). Ele só sobe quando pedido explicitamente.

> **ATENÇÃO:** com o Auth emulado ativo, a Function passa a aceitar **apenas** tokens do emulador. O app rodando no Chrome, logado no Firebase real, recebe `401` e mostra a reputação como "verificação não concluída". Para usar o app, volte a rodar só `--only functions`.

No PowerShell, use `curl.exe` (e não `curl`, que é um apelido de outro comando).

1. **[TERMINAL]** Subir Functions e Auth:
   ```
   firebase emulators:start --only functions,auth
   ```

2. **[TERMINAL]** Criar um usuário de teste no Auth emulado. O e-mail e a senha são fictícios e só existem no emulador; nada é criado no projeto real. A resposta traz o campo `idToken`:
   ```
   curl.exe -X POST "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake" -H "Content-Type: application/json" -d "{\"email\":\"teste@exemplo.com\",\"password\":\"senha-teste-123\",\"returnSecureToken\":true}"
   ```
   Se o usuário já existir, faça login com `accounts:signInWithPassword` no mesmo endereço e com o mesmo corpo.

3. **[TERMINAL]** Chamar a Function com o token, usando o endereço de teste oficial do Google. A resposta deve ser `listado`:
   ```
   curl.exe -X POST -H "Authorization: Bearer <idToken>" -H "Content-Type: application/json" -d "{\"url\":\"http://testsafebrowsing.appspot.com/s/phishing.html\"}" http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio
   ```
   Com `https://www.google.com/` no lugar, a resposta deve ser `nao_listado`.

Os usuários do Auth emulado somem quando o emulador é encerrado.

## Contrato da Function

`POST` com cabeçalho `Authorization: Bearer <ID token do Firebase Auth>` e corpo `{"url": "https://exemplo.com.br/caminho"}`: a URL já normalizada no app, com domínio e caminho, sem query string nem fragmento (arquitetura, seção 4, etapa 2).

| HTTP | Corpo | Significado |
| --- | --- | --- |
| 200 | `{"status":"listado","tiposAmeaca":[...]}` | Consta como malicioso no Google Safe Browsing |
| 200 | `{"status":"nao_listado"}` | Não consta nas listas (não é garantia de ausência de risco) |
| 200 | `{"status":"nao_concluida","motivo":"..."}` | `chave_ausente`, `indisponivel`, `timeout` ou `resposta_inesperada` |
| 400 | `{"erro":"url_invalida"}` | URL ausente, inválida ou com query string, fragmento ou usuário/senha |
| 401 | `{"erro":"nao_autenticado"}` | Sem token ou token inválido |
| 405 | `{"erro":"metodo_nao_permitido"}` | Método diferente de POST |
| 429 | `{"erro":"limite_excedido"}` | Limite de consultas por usuário excedido |

O limite por usuário e os tempos máximos ficam em `functions/src/config.ts`.

Privacidade: a URL consultada vai no corpo do POST (não na URL da chamada) e nenhum log da Function a registra, nem o domínio.

## Troca para a Function publicada (quando o Blaze for ativado)

Nenhuma linha de lógica muda. Muda só a configuração:

1. Publicar: `firebase deploy --only functions`. A chave vai no arquivo local `functions/.env.phize-de7a1`, também ignorado pelo Git (ou, de preferência, no Secret Manager).
2. Rodar o app com o endereço publicado:
   ```
   flutter run --dart-define=PHIZE_FUNCTIONS_URL=https://southamerica-east1-phize-de7a1.cloudfunctions.net
   ```

Antes do deploy, revisar dois pontos:
- **Rate limiting:** o contador fica na memória da instância. É exato no emulador (instância única), mas depois do deploy vale por instância. Por isso a Function está com `maxInstances: 1`. Se precisar escalar, o contador tem que ir para um armazenamento compartilhado.
- **CORS:** está liberado (`cors: true`) para o app rodando no Chrome. A proteção real é o token do Firebase Auth, mas vale restringir às origens do app.
