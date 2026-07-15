# Perfis operacionais MetaGPT

Use um perfil por rodada. Os valores sao pontos de partida para experimento controlado, nao garantias universais de qualidade. Mude uma variavel por vez e compare contra criterios de aceite e testes.

## Regras gerais

- `max_token` limita saida; `context_length` limita entrada. Reserve margem para prompt, documentos e saida dentro do teto real do provedor.
- Temperatura reduz aleatoriedade quando proxima de zero; nao prova qualidade por si so. Mantenha `top_p: 1.0` ao ajustar temperatura para nao confundir efeitos.
- `n_round` limita rodadas da simulacao, nao a quantidade total de chamadas nem a conclusao do projeto.
- `repair_llm_output: true` pode produzir dois niveis de retentativa no MetaGPT. Use apenas para artefatos pequenos e isolados.
- Nao comprimir especificacao, contrato de API, erro de teste, diff ou criterios de aceite. Prefira resumo estruturado de historico repetitivo.

## P1: planejamento de fase

Use para PRD, arquitetura, backlog ou plano de uma unica fase.

```yaml
llm:
  temperature: 0.1
  top_p: 1.0
  max_token: 12000
  reasoning: false
  compress_type: post_cut_by_token
repair_llm_output: false
code_validate_k_times: 1
```

- `n_round`: 3.
- Entrega exigida: um documento e lista curta de criterios de aceite.
- Parar se houver dois papeis consecutivos sem novo arquivo.

## P2: JSON estruturado pequeno

Use para uma tabela, plano de alteracao de um modulo, schema ou resposta que sera desserializada.

```yaml
llm:
  temperature: 0.0
  top_p: 1.0
  max_token: 8000
  reasoning: false
repair_llm_output: false
code_validate_k_times: 1
```

- `n_round`: 1 a 2.
- Proibir Markdown fora do JSON e limitar explicitamente numero de itens/arquivos.
- Se a resposta esperada ultrapassar 8k tokens, dividir a tarefa antes da chamada. Nao elevar o teto para tentar serializar um projeto inteiro.
- Em JSON invalido, registrar o erro e mudar escopo/modelo; nao repetir o mesmo prompt tres vezes.

## P3: revisao e correcao orientada por teste

Use depois de um teste, build, lint ou erro concreto.

```yaml
llm:
  temperature: 0.0
  top_p: 1.0
  max_token: 8000
  reasoning: false
repair_llm_output: false
code_validate_k_times: 1
```

- Enviar somente erro reproduzivel, arquivo ou diff minimo e criterio de aceite.
- Uma correcao por rodada; testar imediatamente.
- Aumentar `code_validate_k_times` para 2 apenas no marco de release e apenas se o primeiro ciclo passou em testes.

## P4: exploracao controlada

Use para alternativas de arquitetura, mapeamento de planilha ou levantamento de riscos. Nao usar para JSON, migracao ou codigo final.

```yaml
llm:
  temperature: 0.3
  top_p: 1.0
  max_token: 6000
  reasoning: false
repair_llm_output: false
```

- Produzir no maximo tres alternativas, com premissas, risco e decisao recomendada.
- Converter a decisao para documento curto antes de iniciar implementacao.

## P5: recuperacao de formato pequeno

Use somente quando um artefato pequeno e claramente truncado ou tem erro de delimitador reparavel.

```yaml
llm:
  temperature: 0.0
  top_p: 1.0
  max_token: 4000
  reasoning: false
repair_llm_output: true
code_validate_k_times: 1
```

- `n_round`: 1.
- Monitorar o log. Parar apos tres avisos de reparo, repeticao textual ou ausencia de novo arquivo.
- Nao usar P5 para `WriteCodePlanAndChange` de projeto amplo: o piloto confirmou falha estrutural nesse caso.

## Orcamento externo por fase

Definir antes de iniciar: `maximo de chamadas`, `maximo de modelos`, `maximo de tentativas por erro` e `artefato de sucesso`.

| Tipo | Chamadas planejadas | Modelos | Tentativas por falha | Sucesso observavel |
|---|---:|---:|---:|---|
| Planejamento | 6 | 1 | 1 | PRD/plano salvo e validado |
| JSON pequeno | 3 | 1 | 1 | JSON desserializado |
| Correcao de teste | 4 | 1 | 1 | teste passa |
| Exploracao | 3 | 1 | 0 | decisao curta registrada |
| Recuperacao | 3 | 1 | 0 apos reparo | artefato valido ou parada clara |

Trocar de modelo somente por 429 persistente, indisponibilidade ou falha de formato comprovada. Nao rotacionar chaves para ampliar franquia.

## Memoria e contexto por fase

Manter quatro arquivos curtos:

1. `SPEC.md`: requisitos autoritativos, imutavel durante a fase.
2. `STATE.md`: feito, pendente, arquivos alterados, testes e bloqueios.
3. `DECISIONS.md`: decisoes com motivo e alternativas rejeitadas.
4. `HANDOFF.md`: entrada minima para a proxima rodada.

Injetar `SPEC.md` integralmente apenas quando necessario. Nas rodadas seguintes, injetar `HANDOFF.md`, a decisao relevante e os caminhos dos artefatos; verificar arquivos no ambiente em vez de repetir documentos inteiros.
