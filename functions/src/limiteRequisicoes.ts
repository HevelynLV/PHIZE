/**
 * Rate limiting por usuário, em janela deslizante e em memória.
 *
 * Limitação registrada: o estado vive na instância da Function. No
 * emulador há uma única instância, então o limite é exato. Após o deploy,
 * cada instância mantém seu próprio contador — o limite efetivo passa a
 * ser LIMITE × número de instâncias. Por isso a Function é publicada com
 * `maxInstances` baixo (ver index.ts).
 *
 * Guarda apenas o uid e os horários das chamadas — nunca o domínio
 * consultado.
 */
export class LimiteRequisicoes {
  private readonly chamadas = new Map<string, number[]>();

  constructor(
    private readonly limite: number,
    private readonly janelaMs: number,
    private readonly agora: () => number = Date.now,
  ) {}

  /** Registra a chamada e devolve `false` se o usuário excedeu o limite. */
  permitir(uid: string): boolean {
    const agora = this.agora();
    const inicioJanela = agora - this.janelaMs;
    const recentes = (this.chamadas.get(uid) ?? []).filter(
      (instante) => instante > inicioJanela,
    );

    if (recentes.length >= this.limite) {
      this.chamadas.set(uid, recentes);
      return false;
    }

    recentes.push(agora);
    this.chamadas.set(uid, recentes);
    return true;
  }
}
