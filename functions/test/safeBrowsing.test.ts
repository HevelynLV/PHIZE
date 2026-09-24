import assert from "node:assert/strict";
import { test } from "node:test";

import { LimiteRequisicoes } from "../src/limiteRequisicoes";
import {
  consultarSafeBrowsing,
  urlValida,
  interpretarResposta,
} from "../src/safeBrowsing";

const respostaJson = (corpo: unknown, status = 200): typeof fetch =>
  (async () =>
    new Response(JSON.stringify(corpo), { status })) as typeof fetch;

test("listado: devolve os tipos de ameaça", async () => {
  const r = await consultarSafeBrowsing("http://golpe.com/login", "k", {
    timeoutMs: 1000,
    fetchFn: respostaJson({
      matches: [{ threatType: "SOCIAL_ENGINEERING" }],
    }),
  });
  assert.deepEqual(r, {
    status: "listado",
    tiposAmeaca: ["SOCIAL_ENGINEERING"],
  });
});

test("corpo vazio: não listado", async () => {
  const r = await consultarSafeBrowsing("https://itau.com.br/", "k", {
    timeoutMs: 1000,
    fetchFn: respostaJson({}),
  });
  assert.deepEqual(r, { status: "nao_listado" });
});

test("chave ausente: não concluída, sem chamada de rede", async () => {
  let chamou = false;
  const r = await consultarSafeBrowsing("https://itau.com.br/", undefined, {
    timeoutMs: 1000,
    fetchFn: (async () => {
      chamou = true;
      return new Response("{}");
    }) as typeof fetch,
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "chave_ausente" });
  assert.equal(chamou, false);
});

test("HTTP 503: indisponível", async () => {
  const r = await consultarSafeBrowsing("https://itau.com.br/", "k", {
    timeoutMs: 1000,
    fetchFn: respostaJson({ error: {} }, 503),
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "indisponivel" });
});

test("falha de conexão: indisponível", async () => {
  const r = await consultarSafeBrowsing("https://itau.com.br/", "k", {
    timeoutMs: 1000,
    fetchFn: (async () => {
      throw new TypeError("fetch failed");
    }) as typeof fetch,
  });
  assert.deepEqual(r, { status: "nao_concluida", motivo: "indisponivel" });
});

test("timeout: não concluída por timeout", async () => {
  const r = await consultarSafeBrowsing("https://itau.com.br/", "k", {
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

test("corpo que não é JSON: resposta inesperada", async () => {
  const r = await consultarSafeBrowsing("https://itau.com.br/", "k", {
    timeoutMs: 1000,
    fetchFn: (async () => new Response("<html>")) as typeof fetch,
  });
  assert.deepEqual(r, {
    status: "nao_concluida",
    motivo: "resposta_inesperada",
  });
});

test("formatos inesperados nunca viram 'não listado'", () => {
  for (const corpo of [null, [], "x", { outra: 1 }, { matches: [] }]) {
    assert.equal(interpretarResposta(corpo).status, "nao_concluida");
  }
});

test("envia a URL recebida, sem alterá-la", async () => {
  let corpo: any;
  await consultarSafeBrowsing("https://site.com.br/wp/banco/login", "k", {
    timeoutMs: 1000,
    fetchFn: (async (_u: string, init?: RequestInit) => {
      corpo = JSON.parse(String(init?.body));
      return new Response("{}");
    }) as typeof fetch,
  });
  assert.deepEqual(corpo.threatInfo.threatEntries, [
    { url: "https://site.com.br/wp/banco/login" },
  ]);
});

test("validação da URL recebida", () => {
  assert.ok(urlValida("https://itau.com.br/"));
  assert.ok(urlValida("http://sub.exemplo.com/caminho/pagina.html"));
  for (const v of [
    "",
    "itau.com.br",
    "https://itau.com.br/?cpf=123",
    "https://itau.com.br/#frag",
    "https://itau.com.br/?",
    "https://usuario:senha@itau.com.br/",
    "ftp://itau.com.br/",
    "http://localhost/",
    "https://" + "a".repeat(2050) + ".com/",
    42,
    null,
  ]) {
    assert.equal(urlValida(v), false, String(v).slice(0, 60));
  }
});

test("rate limiting por usuário, em janela deslizante", () => {
  let agora = 0;
  const limite = new LimiteRequisicoes(2, 1000, () => agora);
  assert.ok(limite.permitir("u1"));
  assert.ok(limite.permitir("u1"));
  assert.equal(limite.permitir("u1"), false);
  assert.ok(limite.permitir("u2"), "o limite é por usuário");
  agora = 1001;
  assert.ok(limite.permitir("u1"), "a janela expira");
});
