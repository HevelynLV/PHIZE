/**
 * Configuração da camada intermediária (arquitetura, seção 2 — Proteção de
 * Credenciais). Valores operacionais da Function, sem relação com os pesos
 * do Score de Risco (esses ficam exclusivamente em docs/score-calibracao.md
 * e no ScoreConfig do app).
 */

/** Região de publicação (São Paulo). O emulador usa o mesmo nome na URL. */
export const REGIAO = "southamerica-east1";

/** Máximo de consultas aceitas por usuário dentro de JANELA_LIMITE_MS. */
export const LIMITE_REQUISICOES_POR_USUARIO = 30;

/** Janela deslizante do rate limiting por usuário. */
export const JANELA_LIMITE_MS = 60_000;

/**
 * Tempo máximo de espera pelo Safe Browsing. Menor que o timeout do app
 * (5 s, RNF03), para que a Function responda "não concluída" antes de o
 * app desistir por conta própria.
 */
export const TIMEOUT_SAFE_BROWSING_MS = 4_000;

/** Nome da variável de ambiente que guarda a chave do Safe Browsing. */
export const VARIAVEL_CHAVE_SAFE_BROWSING = "SAFE_BROWSING_API_KEY";

/**
 * Máximo de análises de texto (LLM) aceitas por usuário dentro de
 * JANELA_LIMITE_MS. Menor que o da reputação: cada chamada tem custo
 * recorrente (arquitetura, seção 2 — Custos Operacionais).
 */
export const LIMITE_ANALISES_TEXTO_POR_USUARIO = 10;

/**
 * Tempo máximo de espera pelo Gemini. Menor que o timeout do app, para que
 * a Function responda "não concluída" antes de o app desistir.
 */
export const TIMEOUT_LLM_MS = 25_000;

/** Maior texto mascarado aceito, em caracteres. */
export const TAMANHO_MAXIMO_TEXTO = 8_000;

/** Nome da variável de ambiente que guarda a chave do Gemini. */
export const VARIAVEL_CHAVE_GEMINI = "GEMINI_API_KEY";

/** Variável de ambiente opcional com o modelo do Gemini a usar. */
export const VARIAVEL_MODELO_GEMINI = "GEMINI_MODEL";

/** Modelo usado quando VARIAVEL_MODELO_GEMINI não está definida. */
export const MODELO_GEMINI_PADRAO = "gemini-2.5-flash";
