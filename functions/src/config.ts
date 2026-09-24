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
