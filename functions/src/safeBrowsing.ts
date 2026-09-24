/**
 * Consulta de reputação na Google Safe Browsing API v4, sobre a URL
 * normalizada (domínio e caminho; arquitetura, seção 4, etapa 2). Nunca
 * lança exceção: toda falha vira
 * resultado "nao_concluida" com um motivo (CLAUDE.md, Seção 8 —
 * Degradação Controlada).
 *
 * Nenhuma função deste módulo registra a URL ou o domínio em log.
 */

export type MotivoNaoConcluida =
  | "chave_ausente"
  | "indisponivel"
  | "timeout"
  | "resposta_inesperada";

export type ResultadoReputacao =
  | { status: "listado"; tiposAmeaca: string[] }
  | { status: "nao_listado" }
  | { status: "nao_concluida"; motivo: MotivoNaoConcluida };

const ENDPOINT = "https://safebrowsing.googleapis.com/v4/threatMatches:find";

const TIPOS_AMEACA = [
  "MALWARE",
  "SOCIAL_ENGINEERING",
  "UNWANTED_SOFTWARE",
  "POTENTIALLY_HARMFUL_APPLICATION",
];

/** Hostname válido: rótulos alfanuméricos com hífen interno, ao menos um ponto. */
const PADRAO_DOMINIO =
  /^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]{2,63}$/;

const TAMANHO_MAXIMO_URL = 2048;

/**
 * Valida a URL recebida do app, já normalizada no dispositivo
 * (`normalizarUrlReputacao`): esquema http/https, host válido e caminho.
 *
 * Rejeita query string, fragmento e usuário/senha em vez de removê-los: o
 * descarte é obrigação do app, antes da transmissão (arquitetura, seção 4,
 * etapa 2). Receber qualquer um deles indica cliente fora do contrato.
 */
export function urlValida(valor: unknown): valor is string {
  if (typeof valor !== "string" || valor.length > TAMANHO_MAXIMO_URL) {
    return false;
  }
  // Checagem textual antes do parser: `new URL` descarta um "?" ou "#"
  // vazio no final, e a regra é que eles nem cheguem.
  if (valor.includes("?") || valor.includes("#")) return false;

  let url: URL;
  try {
    url = new URL(valor);
  } catch {
    return false;
  }
  return (
    (url.protocol === "http:" || url.protocol === "https:") &&
    url.username === "" &&
    url.password === "" &&
    PADRAO_DOMINIO.test(url.hostname)
  );
}

export async function consultarSafeBrowsing(
  url: string,
  chave: string | undefined,
  opcoes: { timeoutMs: number; fetchFn?: typeof fetch },
): Promise<ResultadoReputacao> {
  if (!chave) {
    return { status: "nao_concluida", motivo: "chave_ausente" };
  }

  const fetchFn = opcoes.fetchFn ?? fetch;
  const controle = new AbortController();
  const temporizador = setTimeout(() => controle.abort(), opcoes.timeoutMs);

  let resposta: Response;
  try {
    // A chave vai na query string, como exige a API; a URL consultada vai
    // no corpo. Nenhuma das duas é registrada em log.
    resposta = await fetchFn(`${ENDPOINT}?key=${encodeURIComponent(chave)}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client: { clientId: "phize", clientVersion: "1.0.0" },
        threatInfo: {
          threatTypes: TIPOS_AMEACA,
          platformTypes: ["ANY_PLATFORM"],
          threatEntryTypes: ["URL"],
          threatEntries: [{ url }],
        },
      }),
      signal: controle.signal,
    });
  } catch (erro) {
    clearTimeout(temporizador);
    if (controle.signal.aborted) {
      return { status: "nao_concluida", motivo: "timeout" };
    }
    return { status: "nao_concluida", motivo: "indisponivel" };
  }

  try {
    if (!resposta.ok) {
      return { status: "nao_concluida", motivo: "indisponivel" };
    }

    const corpo: unknown = await resposta.json();
    return interpretarResposta(corpo);
  } catch {
    if (controle.signal.aborted) {
      return { status: "nao_concluida", motivo: "timeout" };
    }
    return { status: "nao_concluida", motivo: "resposta_inesperada" };
  } finally {
    clearTimeout(temporizador);
  }
}

/**
 * A API devolve `{}` quando não há correspondência e `{ matches: [...] }`
 * quando o endereço está listado. Qualquer outro formato é tratado como
 * resposta inesperada — nunca como "não listado".
 */
export function interpretarResposta(corpo: unknown): ResultadoReputacao {
  if (typeof corpo !== "object" || corpo === null || Array.isArray(corpo)) {
    return { status: "nao_concluida", motivo: "resposta_inesperada" };
  }

  const matches = (corpo as { matches?: unknown }).matches;
  if (matches === undefined) {
    return Object.keys(corpo).length === 0
      ? { status: "nao_listado" }
      : { status: "nao_concluida", motivo: "resposta_inesperada" };
  }

  if (!Array.isArray(matches) || matches.length === 0) {
    return { status: "nao_concluida", motivo: "resposta_inesperada" };
  }

  const tiposAmeaca = [
    ...new Set(
      matches
        .map((m) => (m as { threatType?: unknown })?.threatType)
        .filter((t): t is string => typeof t === "string"),
    ),
  ];
  return { status: "listado", tiposAmeaca };
}
