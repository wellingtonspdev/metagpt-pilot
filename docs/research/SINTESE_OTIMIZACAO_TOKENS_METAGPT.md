# Sintese Operacional: Tokens, Objetividade e Confiabilidade no MetaGPT

Base: [pesquisa de fontes](PESQUISA_OTIMIZACAO_TOKENS_AGENTES.md), configuracao oficial local e piloto realizado em 2026-07-14.

## Objetivo

Otimizar tokens significa aumentar a taxa de artefatos corretos, testes aprovados e decisoes aproveitaveis por chamada. Nao significa reduzir artificialmente toda saida. A economia ocorre ao eliminar contexto redundante, tentativas equivalentes, revisao sem criterio e loops sem sinal novo.

## Principios adotados

1. **Separar tipos de trabalho.** Planejamento, JSON estruturado, exploracao, correcao e implementacao ampla possuem formatos e riscos diferentes. Cada rodada recebe apenas um objetivo verificavel.
2. **Ancorar em evidencia externa.** Para codigo, usar teste, build, lint, diff ou arquivo salvo como sinal. Para planejamento, usar criterio de aceite e artefato salvo. Isso segue a ideia de intercalar acao e observacao do ReAct.
3. **Refletir com limite.** Feedback curto pode melhorar resultados, como mostram Reflexion e Self-Refine, mas uma reflexao so e permitida depois de erro real e antes de uma unica nova tentativa.
4. **Usar memoria em camadas.** Requisitos e decisoes permanecem em arquivos duraveis. A rodada recebe apenas handoff, decisao relevante e caminhos de arquivos, inspirada na separacao de memoria do MemGPT.
5. **Evitar raciocinio verboso por padrao.** Planos e diagnosticos devem conter fatos, hipotese, evidencia, proxima acao e criterio de parada. Chain of Draft e a base para essa concisao, mas nao deve suprimir informacao de seguranca, contratos ou codigo.
6. **Orcamento externo e criterios de parada.** `n_round` e `max_token` nao impedem todos os loops internos. O piloto monitora chamadas, reparos JSON, repeticao e artefatos novos.

## Temperatura: como usar

Temperatura altera a distribuicao de amostragem: proxima de zero favorece escolhas mais deterministicas; maior temperatura aumenta variedade. Ela nao garante mais inteligencia. Um estudo nao encontrou diferenca estatisticamente significativa entre 0 e 1 em MCQA, enquanto outro associou maior temperatura a pior autocorrecao.

Decisao operacional:

| Acao | Temperatura inicial | Motivo |
|---|---:|---|
| JSON, schema, codigo, revisao, correcao de teste | `0.0` | Reprodutibilidade e menor variacao de formato |
| PRD, arquitetura e plano de fase | `0.1` | Pequena flexibilidade sem aleatoriedade alta |
| Exploracao de alternativas | `0.3` | Diversidade controlada, limitada a tres opcoes |

Manter `top_p: 1.0` durante os experimentos de temperatura. Alterar temperatura e `top_p` simultaneamente impede atribuir causa a uma melhora ou piora.

## Perfis de execucao

Os perfis detalhados foram incorporados em `metagpt-pilot/references/execution-profiles.md`.

| Perfil | Uso | Saida maxima inicial | Rodadas | Reparo JSON |
|---|---|---:|---:|---|
| P1 | Planejamento de uma fase | 12k | 3 | Desligado |
| P2 | JSON pequeno | 8k | 1-2 | Desligado |
| P3 | Correcao orientada por teste | 8k | conforme falha | Desligado |
| P4 | Exploracao | 6k | curta | Desligado |
| P5 | Recuperacao de formato pequeno | 4k | 1 | Ligado, monitorado |

`max_token` e teto de saida, nao meta de tamanho. Se a resposta precisa ser maior que o teto do perfil, a tarefa foi dimensionada incorretamente e deve ser dividida.

## Controle de loops

Interromper e registrar estado quando ocorrer qualquer condicao:

- tres avisos de reparo JSON na mesma acao;
- duas transicoes de papel sem novo artefato;
- texto repetido sem novo arquivo ou teste;
- 429 persistente apos respeitar `Retry-After` e uma nova tentativa;
- mesmo erro de teste apos uma correcao sem mudanca de hipotese;
- limite de chamadas da fase atingido.

O MetaGPT local tem comportamento relevante: `repair_llm_output=true` pode combinar retentativas de chamada e reparo de JSON. Portanto, P5 e exclusivo para artefatos pequenos. O fluxo amplo `WriteCodePlanAndChange` nao deve ser repetido em modelos que ja falharam nesse contrato.

## Estrutura de memoria por fase

Criar e manter:

```text
.planning/
  SPEC.md       # requisito autoritativo
  STATE.md      # estado factual e testes
  DECISIONS.md  # decisoes e justificativas
  HANDOFF.md    # entrada minima da proxima rodada
```

Nunca comprimir: especificacao autoritativa, contratos de API, diffs relevantes, logs de erro necessarios, migracoes e criterios de aceite. Resumir somente historico repetitivo, discussao ja decidida e saídas superseded.

## Papel recomendado do MetaGPT

1. Usar MetaGPT para PRD, arquitetura, backlog, revisao de design e tarefas estreitas.
2. Nao usar uma unica rodada para gerar o MVP inteiro quando o provedor/modelo nao entrega JSON estruturado confiavel.
3. Implementar em fases pequenas com testes locais; entregar ao MetaGPT apenas o contexto minimo para revisao ou proxima decisao.
4. Antes de qualquer reexecucao, comparar artefatos com `agents.md` e restaurar snapshot quando a workspace tiver sido reorganizada.

## Experimento de validacao recomendado

Para validar esses perfis sem desperdiçar quota:

1. Escolher uma unica fase pequena com criterio de aceite objetivo.
2. Rodar P1 uma vez e registrar chamadas, tempo, arquivos e aderencia ao criterio.
3. Rodar P2 somente para um schema ou lista limitada.
4. Executar teste/lint local.
5. Registrar aprendizado verificado na skill.
6. Alterar somente uma variavel no proximo experimento: modelo, temperatura, `max_token` ou estrategia de memoria.

## Limites desta sintese

Os resultados de papers dependem de modelos, benchmarks e tarefas diferentes. Os valores numericos sao pontos de partida que exigem medicao no provedor e modelo selecionados. A skill deve registrar apenas experiencia comprovada antes de transformar uma regra em padrao global.
