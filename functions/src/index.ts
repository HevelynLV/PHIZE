/**
 * Camada intermediária do Phize (arquitetura, seção 2 — Proteção de
 * Credenciais): as chaves das APIs de terceiros ficam no servidor e nunca
 * no pacote do app.
 *
 * Nesta fase roda apenas no emulador local (docs/ROADMAP.md, Fase 5). O
 * mesmo código é publicado depois sem alteração; muda só a URL que o app
 * recebe por configuração.
 *
 * Privacidade: nenhum log desta Function contém a URL ou o domínio
 * consultados. A URL chega no corpo do POST (e não na URL da chamada) para
 * não aparecer nos registros de requisição do emulador ou do Cloud Run.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import * as logger from "firebase-functions/logger";
import { onRequest } from "firebase-functions/v2/https";

import {
  JANELA_LIMITE_MS,
  LIMITE_REQUISICOES_POR_USUARIO,
  REGIAO,
  TIMEOUT_SAFE_BROWSING_MS,
  VARIAVEL_CHAVE_SAFE_BROWSING,
} from "./config";
import { LimiteRequisicoes } from "./limiteRequisicoes";
import { consultarSafeBrowsing, urlValida } from "./safeBrowsing";

initializeApp();

const limite = new LimiteRequisicoes(
  LIMITE_REQUISICOES_POR_USUARIO,
  JANELA_LIMITE_MS,
);

/**
 * POST com `Authorization: Bearer <ID token do Firebase Auth>` e corpo
 * `{ "url": "https://exemplo.com.br/caminho" }` — URL já normalizada no
 * app: domínio e caminho, sem query string nem fragmento.
 *
 * Respostas:
 * - 200 `{ status: "listado", tiposAmeaca: [...] }`
 * - 200 `{ status: "nao_listado" }`
 * - 200 `{ status: "nao_concluida", motivo: "..." }`
 * - 400 URL ausente, inválida ou com query/fragmento/credenciais
 * - 401 sem token ou token inválido
 * - 405 método diferente de POST
 * - 429 limite de requisições do usuário excedido
 */
export const reputacaoDominio = onRequest(
  // `cors: true` permite a chamada a partir do app rodando no Chrome. A
  // proteção real é o token do Firebase Auth, exigido abaixo.
  { region: REGIAO, cors: true, maxInstances: 1 },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).json({ erro: "metodo_nao_permitido" });
        return;
      }

      const cabecalho = req.get("Authorization") ?? "";
      const token = cabecalho.startsWith("Bearer ")
        ? cabecalho.slice("Bearer ".length).trim()
        : "";
      if (!token) {
        res.status(401).json({ erro: "nao_autenticado" });
        return;
      }

      let uid: string;
      try {
        uid = (await getAuth().verifyIdToken(token)).uid;
      } catch {
        res.status(401).json({ erro: "nao_autenticado" });
        return;
      }

      if (!limite.permitir(uid)) {
        res.status(429).json({ erro: "limite_excedido" });
        return;
      }

      const url: unknown = req.body?.url;
      if (!urlValida(url)) {
        res.status(400).json({ erro: "url_invalida" });
        return;
      }

      const resultado = await consultarSafeBrowsing(
        url,
        process.env[VARIAVEL_CHAVE_SAFE_BROWSING],
        { timeoutMs: TIMEOUT_SAFE_BROWSING_MS },
      );

      if (resultado.status === "nao_concluida") {
        // Só o motivo — nunca a URL nem o domínio.
        logger.warn("Safe Browsing não concluído", {
          motivo: resultado.motivo,
        });
      }

      res.status(200).json(resultado);
    } catch {
      // Rede de segurança: nenhuma falha derruba a Function nem expõe
      // detalhes (nem a URL) na resposta ou no log.
      logger.error("Falha inesperada na consulta de reputação");
      if (!res.headersSent) {
        res
          .status(200)
          .json({ status: "nao_concluida", motivo: "indisponivel" });
      }
    }
  },
);
