# MetaGPT Pilot

> Skill operacional para iniciar, acompanhar, recuperar e encerrar execucoes do [MetaGPT](https://github.com/FoundationAgents/MetaGPT) com evidencias, preservacao de workspace e controle de falhas.

![Status](https://img.shields.io/badge/status-beta%20interna-f59e0b?style=flat-square)
![MetaGPT](https://img.shields.io/badge/MetaGPT-pilotagem-2563eb?style=flat-square)
![Licenca](https://img.shields.io/badge/licenca-a%20definir-64748b?style=flat-square)

## Objetivo

O MetaGPT Pilot nao substitui o MetaGPT nem altera seu codigo-fonte. Ele fornece um procedimento reutilizavel para conduzir execucoes do framework com mais previsibilidade, especialmente quando ha `agents.md`, Docker, OpenRouter, modelos gratuitos, limites de provedor, saidas JSON estruturadas e necessidade de recuperar uma rodada interrompida.

O foco e transformar pedidos amplos em rodadas pequenas, observaveis e recuperaveis. A skill orienta o operador a preservar especificacoes, registrar estado, verificar artefatos reais e parar com um motivo claro quando nao houver progresso comprovado.

## O que esta no pacote

| Arquivo | Papel |
| --- | --- |
| [SKILL.md](SKILL.md) | Fluxo principal de pilotagem e criterios de encerramento. |
| [references/execution-profiles.md](references/execution-profiles.md) | Perfis P1-P5 para planejamento, JSON pequeno, correcao, exploracao e recuperacao. |
| [references/failure-playbook.md](references/failure-playbook.md) | Sinais de falha e a acao recomendada. |
| [references/parallel-sessions.md](references/parallel-sessions.md) | Isolamento, concorrencia e chaves por sessao. |
| [references/experience-log.md](references/experience-log.md) | Registro curto de aprendizados comprovados. |
| [scripts/record-experience.ps1](scripts/record-experience.ps1) | Registro padronizado de experiencias sem segredos. |
| [templates/](templates) | Template de configuracao, launcher e monitor para uma sessao isolada. |
| [agents/openai.yaml](agents/openai.yaml) | Metadados para ambientes compativeis. |

## Como a skill foi desenvolvida

A skill nasceu de uma pilotagem real de MetaGPT em Windows, Docker e OpenRouter. O processo observou falhas concretas e as converteu em regras operacionais, em vez de depender apenas de recomendacoes genericas.

Os principais problemas observados foram:

- o MetaGPT nao le de forma confiavel um requisito apenas por estar em volume montado;
- tarefas grandes que exigem JSON estruturado podem exceder a capacidade pratica de modelos gratuitos e falhar na desserializacao;
- um processo pode encerrar com `NORMAL_EXIT` mesmo apos uma falha interna, portanto o status do container sozinho nao comprova conclusao;
- provedores gratuitos podem retornar indisponibilidade ou limite temporario;
- uma importacao aparentemente bem-sucedida pode gerar zero entidades normalizadas, exigindo validacao da cadeia completa de dados.

Com base nisso, a skill passou a exigir injecao explicita da especificacao, perfis por tipo de tarefa, snapshots, verificacao por artefatos e testes, limites de repeticao e motivos de parada padronizados.

## Principios operacionais

1. **Uma fase por rodada.** Nao solicitar a construcao integral de um MVP quando a etapa exige saida estruturada.
2. **Especificacao autoritativa fora da workspace.** Criar copia imutavel e injetar o conteudo relevante no prompt.
3. **Progresso precisa ser observavel.** Arquivos salvos, mudanca de papel, testes ou build; texto do modelo nao basta.
4. **Recuperar sem apagar evidencia.** Parar o container improdutivo, preservar workspace, logs e Git.
5. **Repeticao tem limite.** Nao insistir no mesmo modelo ou prompt depois de falha de formato persistente.
6. **Chaves nao sao mecanismo de contorno.** Respeitar `Retry-After`, aplicar backoff e nunca rotacionar chaves para burlar franquias.
7. **Parada deve ser explicita.** Usar `COMPLETED`, `UPSTREAM_RATE_LIMIT`, `STRUCTURED_OUTPUT_FAILURE`, `DAILY_QUOTA_EXHAUSTED` ou `PROJECT_DECISION_REQUIRED`.

## Uso rapido

1. Copie esta pasta para o diretorio global de skills do seu runtime.
2. Leia [SKILL.md](SKILL.md) e escolha um perfil em [execution-profiles.md](references/execution-profiles.md).
3. Informe caminho do projeto, especificacao, objetivo da rodada e se a execucao pode ser autonoma.
4. Execute uma fase limitada, monitore logs e artefatos, e registre o resultado.

Exemplo de pedido:

```text
Use $metagpt-pilot para executar a fase de importacao em D:\MeuProjeto.
Leia agents.md, crie snapshot, injete a especificacao no prompt, monitore o container
e pare apenas por conclusao comprovada ou falha com motivo explicito.
```

Para diagnostico sem executar:

```text
Use $metagpt-pilot em modo somente analise e avalie este log: <erro ou caminho do log>.
```

## Sessoes paralelas

O pacote inclui um template para preparar uma segunda sessao sem compartilhar workspace, container, configuracao runtime, logs ou snapshots. A chave e lida de uma variavel de ambiente exclusiva da sessao e nao entra no Git.

Consulte [parallel-sessions.md](references/parallel-sessions.md) antes de executar duas rodadas. Chaves diferentes podem separar orcamento e auditoria por projeto, mas nao ampliam rate limits globais nem devem ser usadas para contornar limites de provedor.

## Desenvolvimento autonomo a partir de agents.md

Quando o objetivo for desenvolver um projeto de ponta a ponta, a skill usa `agents.md` como contrato autoritativo e executa o ciclo: contexto -> plano de fase -> implementacao -> verificacao -> atualizacao de estado -> proxima fase. A IA piloto continua sem pedir confirmacao para operacoes reversiveis e baseadas no contrato.

Ela deve parar somente diante de decisao material ausente, ausencia de solucao tecnica segura, limite persistente do provedor, falha de formato repetida ou guarda preventiva de orcamento. O fluxo completo e os codigos de parada estao em [autonomous-project-workflow.md](references/autonomous-project-workflow.md).

O limiar de 5% se aplica apenas a um orcamento que possa ser observado de forma confiavel. Para limites gratuitos que o provedor nao reporte como saldo de requisicoes, a skill usa um teto local conservador e nao promete uma medicao exata.

## Evidencias ja validadas

| Cenario | Resultado observado | Situacao |
| --- | --- | --- |
| MetaGPT oficial em Docker/OpenRouter | Execucao iniciada e monitorada sem alterar o fonte do framework. | Validado |
| Requisito montado vs. injetado | O requisito precisava ser injetado explicitamente no prompt para uso confiavel. | Validado |
| Falha de JSON grande | Respostas extensas causaram `JSONDecodeError`; fases menores reduziram o risco. | Validado |
| Limite de provedor | Houve indisponibilidade/limite temporario de worker; insistencia em loop foi evitada. | Validado |
| Encerramento enganoso | `NORMAL_EXIT` nao foi tratado como evidencia suficiente de entrega. | Validado |
| Importacao de planilha | Foram verificados arquivo, lote, registros normalizados, endpoint agregado e interface. | Validado |
| Registro de aprendizado | O pacote separa fato comprovado de especulacao e evita registrar segredos. | Validado |

## O que ainda precisa ser testado

Esta versao deve ser tratada como **beta interna**. Antes de considera-la consolidada, sao necessarios os experimentos abaixo.

| Prioridade | Experimento | Criterio de aceite |
| --- | --- | --- |
| Alta | Projeto limpo de ponta a ponta | Um repositorio descartavel passa por planejamento, implementacao, testes, commit e encerramento com a skill como unico procedimento operacional. |
| Alta | Recuperacao forcada | Interromper um container e retomar do snapshot sem perda de workspace, com motivo de parada correto. |
| Alta | 429 e fallback | Confirmar backoff, uma tentativa adicional e decisao correta ao persistir o limite; validar se o cliente MetaGPT suporta o fallback configurado. |
| Alta | Seguranca de logs | Confirmar que chaves, headers de autorizacao e dados privados nao aparecem em logs, snapshots ou relatorios. |
| Media | Perfis P1-P5 | Executar cada perfil pelo menos uma vez, com artefato e teste de sucesso definidos. |
| Media | Portabilidade | Invocar a skill de fato em Codex, OpenCode, Gemini CLI e Antigravity; confirmar descoberta e leitura do `SKILL.md`. |
| Media | Medicao de eficiencia | Comparar um caso igual com e sem a skill: chamadas, falhas, tempo, artefatos validos e intervencoes humanas. |

## Protocolo para contribuidores

1. Use um repositorio descartavel e uma chave com permissao minima.
2. Defina um artefato de sucesso e um teto de chamadas antes de iniciar.
3. Registre modelo, perfil, objetivo, resultado, erros e testes executados.
4. Nao publique chaves, prompts completos com dados privados, planilhas reais, tokens de sessao ou logs sensiveis.
5. Para um aprendizado novo, registre um fato curto com `scripts/record-experience.ps1`.
6. Atualize o playbook apenas se a evidencia alterar uma decisao geral da skill.
7. Envie um pull request com reproducao, evidencias e a mudanca proposta.

## Limites conhecidos

- A skill nao elimina limites de RPM, franquia diaria, indisponibilidade de provedor ou qualidade do modelo.
- Ela nao garante que todos os modos internos do MetaGPT utilizem fallback de modelos apenas porque a lista aparece no YAML.
- `max_token` controla saida, mas nao transforma uma tarefa monolitica em uma tarefa serializavel.
- A qualidade do projeto continua dependente de requisitos claros, testes reais e revisao humana de decisoes materiais.

## Estudos e experimentos

Os documentos abaixo preservam as evidencias que deram origem a esta skill. Eles foram revisados para excluir chaves, configuracoes de runtime e logs sensiveis.

| Categoria | Documento |
| --- | --- |
| Pesquisa | [Otimizacao de tokens e agentes](docs/research/PESQUISA_OTIMIZACAO_TOKENS_AGENTES.md) |
| Pesquisa | [Sintese de otimizacao para MetaGPT](docs/research/SINTESE_OTIMIZACAO_TOKENS_METAGPT.md) |
| Viabilidade | [OpenRouter e MetaGPT](docs/research/OPENROUTER_KEY_AND_METAGPT_FEASIBILITY.md) |
| Caso real | [Relatorio de pilotagem](docs/case-studies/RELATORIO_PILOTAGEM_METAGPT.md) |
| Caso real | [Plano de fase e importador](docs/case-studies/fase-2-shopee-pedidos-plan.md) |
| Caso real | [Validacao de frontend](docs/case-studies/metagpt-frontend-validation-2026-07-15.md) |
| Caso real | [Analise de fluxo de dados](docs/case-studies/analise-fluxo-importacao-dashboard-2026-07-15.md) |

## Status de distribuicao

O objetivo desta publicacao e permitir testes independentes por outros desenvolvedores. Resultados reproduziveis devem ser incorporados ao playbook e aos perfis antes de declarar uma versao estavel.

## Licenca

Licenca ainda nao definida. Antes de distribuicao publica ampla, inclua um arquivo `LICENSE` com a permissao de uso escolhida.
