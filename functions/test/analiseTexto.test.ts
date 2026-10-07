import assert from "node:assert/strict";
import { test } from "node:test";

import {
  analisarTextoGemini,
  interpretarRespostaGemini,
  textoValido,
  validarAnalise,
} from "../src/analiseTexto";

const OPCOES = { modelo: "modelo-teste", timeoutMs: 1000 };

/** Corpo no formato do generateContent, com [gerado] como texto do modelo. */
const respostaGemini = (gerado: unknown, finishReason = "STOP") => ({
  candidates: [
    {
      finishReason,
      content: {
        parts: [
          { text: typeof gerado === "string" ? gerado : JSON.stringify(gerado) },
        ],
      },
    },
  ],
});

const fetchJson = (corpo: unknown, status = 200): typeof fetch =>
  (async () => new Response(JSON.stringify(corpo), { status })) as typeof fetch;

const ANALISE_VALIDA = {
  sinais: ["pedido_financeiro", "alegacao_troca_contato"],
  categoria: "falso_contato",
  explicacao: "Pedido de dinheiro de quem diz ter trocado de número.",
};

test("resposta válida: devolve sinais, categoria e explicação, sem score", async () => {
  const r = await analisarTextoGemini("Oi mãe, troquei de número", "k", {
    ...OPCOES,
    fetchFn: fetchJson(respostaGemini(ANALISE_VALIDA)),
  });
  assert.deepEqual(r, { status: "concluida", analise: ANALISE_VALIDA });
  assert.equal("score" in (r as { analise: object }).analise, false);
});

test("chave ausente: não concluída, sem chamada de rede", async () => {
  let chamou = false;
  const r = await analisarTextoGemini("texto", undefined, {
    ...OPCOES,
    fetchFn: (async () => {
      chamou = true;
      return new Response("{}");
    }) as typeof fetch,
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "chave_ausente" });
  assert.equal(chamou, false);
});

test("HTTP 429 do provedor: limite_provedor", async () => {
  const r = await analisarTextoGemini("texto", "k", {
    ...OPCOES,
    fetchFn: fetchJson({ error: { status: "RESOURCE_EXHAUSTED" } }, 429),
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "limite_provedor" });
});

test("HTTP 500: indisponível", async () => {
  const r = await analisarTextoGemini("texto", "k", {
    ...OPCOES,
    fetchFn: fetchJson({}, 500),
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "indisponivel" });
});

test("timeout: não concluída por timeout", async () => {
  const r = await analisarTextoGemini("texto", "k", {
    ...OPCOES,
    timeoutMs: 20,
    fetchFn: ((_url: string, init?: RequestInit) =>
      new Promise((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () =>
          reject(new DOMException("aborted", "AbortError")),
        );
      })) as typeof fetch,
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "timeout" });
});

test("envia o texto no corpo, a chave no cabeçalho e exige JSON", async () => {
  let url = "";
  let init: RequestInit | undefined;
  await analisarTextoGemini("Pix de R$ 500 para [CHAVE_PIX]", "chave-x", {
    ...OPCOES,
    fetchFn: (async (u: string, i?: RequestInit) => {
      url = u;
      init = i;
      return new Response(JSON.stringify(respostaGemini(ANALISE_VALIDA)));
    }) as typeof fetch,
  });
  assert.equal(url.includes("chave-x"), false, "a chave não vai na URL");
  assert.equal(url.includes("Pix"), false, "o texto não vai na URL");
  assert.equal((init?.headers as Record<string, string>)["x-goog-api-key"], "chave-x");
  const corpo = JSON.parse(String(init?.body));
  assert.equal(corpo.contents[0].parts[0].text, "Pix de R$ 500 para [CHAVE_PIX]");
  assert.equal(corpo.generationConfig.responseMimeType, "application/json");
  assert.equal(corpo.generationConfig.temperature, 0);
});

test("formatos fora do contrato viram resposta_invalida, nunca 'sem sinais'", () => {
  const casos: unknown[] = [
    null,
    {},
    { candidates: [] },
    respostaGemini(ANALISE_VALIDA, "SAFETY"),
    respostaGemini(ANALISE_VALIDA, "MAX_TOKENS"),
    respostaGemini("{ isto não é json"),
    respostaGemini({ ...ANALISE_VALIDA, sinais: ["sinal_inventado"] }),
    respostaGemini({ ...ANALISE_VALIDA, sinais: "pedido_financeiro" }),
    // Sem RAG, a correspondência com padrão catalogado não pode ser emitida.
    respostaGemini({
      ...ANALISE_VALIDA,
      sinais: ["correspondencia_padrao_catalogado"],
    }),
    respostaGemini({ ...ANALISE_VALIDA, categoria: "inventada" }),
    respostaGemini({ ...ANALISE_VALIDA, explicacao: "   " }),
    respostaGemini({ sinais: [], categoria: "sem_indicios" }),
  ];
  for (const corpo of casos) {
    assert.deepEqual(interpretarRespostaGemini(corpo), {
      status: "nao_concluida",
      motivo: "resposta_invalida",
    });
  }
});

test("sinais repetidos contam uma vez", () => {
  const r = validarAnalise({
    ...ANALISE_VALIDA,
    sinais: ["ameaca", "ameaca"],
  });
  assert.deepEqual(r?.sinais, ["ameaca"]);
});

test("validação do texto recebido", () => {
  assert.ok(textoValido("Seu CPF foi bloqueado", 100));
  for (const v of ["", "   ", "x".repeat(101), 42, null, undefined, {}]) {
    assert.equal(textoValido(v, 100), false, String(v).slice(0, 30));
  }
});
