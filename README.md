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
| [references/universal-invocation.md](references/universal-invocation.md) | Chamada unica, descoberta de `agents.md` e execucao faseada. |
| [references/model-routing.md](references/model-routing.md) | Matriz de selecao por fase, health check e fallback de modelos. |
| [references/model-research-protocol.md](references/model-research-protocol.md) | Pesquisa por diferenca de catalogo, comparacao e promocao controlada. |
| [references/model-registry.json](references/model-registry.json) | Registro versionado de evidencias, riscos e prioridades de roteamento. |
| [references/experience-log.md](references/experience-log.md) | Registro curto de aprendizados comprovados. |
| [scripts/record-experience.ps1](scripts/record-experience.ps1) | Registro padronizado de experiencias sem segredos. |
| [scripts/select-metagpt-model.ps1](scripts/select-metagpt-model.ps1) | Selecao local por fase, papel, tarefa, complexidade e saude do proxy. |
| [scripts/refresh-metagpt-model-catalog.ps1](scripts/refresh-metagpt-model-catalog.ps1) | Snapshot seguro do catalogo, modelos novos e evidencia vencida. |
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
8. **Modelo por rodada, com evidencia.** Usar `-Model Auto` para classificar a rodada, testar no maximo dois candidatos saudaveis e registrar a decisao; um modelo explicito sempre prevalece.

## Uso rapido

Depois da instalacao unica do MetaGPT, Docker e desta skill, basta chamar a skill. Ela descobre o contrato do projeto, planeja, divide quando necessario, monitora o MetaGPT e continua fase a fase.

Na raiz do projeto:

```text
Use $metagpt-pilot
```

Fora da raiz:

```text
Use $metagpt-pilot para iniciar o projeto em D:\Projetos\MeuProjeto
```

O projeto deve conter `agents.md` ou `AGENTS.md`. Consulte [universal-invocation.md](references/universal-invocation.md) para o contrato completo.

Exemplo de pedido:

```text
Use $metagpt-pilot para iniciar o projeto em D:\MeuProjeto.
```

Para diagnostico sem executar:

```text
Use $metagpt-pilot em modo somente analise e avalie este log: <erro ou caminho do log>.
```

## Selecao automatica de modelos

O launcher usa `-Model Auto` como padrao. Antes de iniciar uma rodada, ele le fase, papel, tarefa e dificuldade, consulta o catalogo atual do proxy e faz um health check curto apenas nos candidatos da rota selecionada. A decisao e gravada no manifesto, sem chaves ou headers.

| Tipo de rodada | Modelo primario atual | Fallbacks principais |
| --- | --- | --- |
| PRD e planejamento | Gemini 3.1 Flash Lite | Nemotron Ultra, North Mini Code |
| Arquitetura e investigacao | DeepSeek V4 Flash | Nemotron Ultra, Gemini Flash Lite |
| Implementacao | Laguna M.1 | North Mini Code, Nemotron Ultra, DeepSeek V4 Flash |
| Revisao e correcao | Nemotron Ultra | DeepSeek V4 Flash, North Mini Code |
| Subtarefa curta | North Mini Code | Laguna XS 2.1, Gemini Flash Lite |

O MetaGPT usa um unico modelo por container. Para aplicar modelos diferentes a Product Manager, Architect, Engineer e QA, o piloto divide o trabalho em rodadas/fases e seleciona o modelo antes de cada rodada. Nao ha troca invisivel de modelo no meio de uma equipe em execucao.

Antes de cada rodada, o seletor consulta o catalogo do 9Router. Modelos novos permanecem fora da matriz critica ate pesquisa em fontes oficiais/independentes e experimentos locais. A pesquisa e acionada por diferenca de catalogo ou evidencia vencida, nao por toda chamada.

Para fixar um modelo em uma rodada especifica, passe `-Model "<id-do-modelo>"`; isso desativa a selecao automatica somente naquela rodada. Consulte [model-routing.md](references/model-routing.md) para limites, health checks e fallbacks.

## Sessoes paralelas

O pacote inclui um template para preparar uma segunda sessao sem compartilhar workspace, container, configuracao runtime, logs ou snapshots. A chave e lida de uma variavel de ambiente exclusiva da sessao e nao entra no Git.

Consulte [parallel-sessions.md](references/parallel-sessions.md) antes de executar duas rodadas. Chaves diferentes podem separar orcamento e auditoria por projeto, mas nao ampliam rate limits globais nem devem ser usadas para contornar limites de provedor.

## Desenvolvimento autonomo a partir de agents.md

Quando o objetivo for desenvolver um projeto de ponta a ponta, a skill usa `agents.md` como contrato autoritativo e executa o ciclo: contexto -> plano de fase -> implementacao -> verificacao -> atualizacao de estado -> proxima fase. A IA piloto continua sem pedir confirmacao para operacoes reversiveis e baseadas no contrato.

Ela deve parar somente diante de decisao material ausente, ausencia de solucao tecnica segura, limite persistente do provedor, falha de formato repetida ou guarda preventiva de orcamento. O fluxo completo e os codigos de parada estao em [autonomous-project-workflow.md](references/autonomous-project-workflow.md).

### Ordem padrao de entrega

1. Banco de dados
2. Autenticacao
3. Permissoes
4. Pipeline de vendas
5. Historico de atividades
6. API
7. Frontend
8. Workflows
9. Agentes de IA

Itens que nao se aplicam devem ser registrados como `NOT_APPLICABLE`; nao devem ser pulados silenciosamente nem usados para antecipar camadas posteriores.

O limiar de 5% se aplica apenas a um orcamento que possa ser observado de forma confiavel. Para limites gratuitos que o provedor nao reporte como saldo de requisicoes, a skill usa um teto local conservador e nao promete uma medicao exata.

### Projetos pequenos e grandes

Projetos pequenos podem ser planejados, implementados e validados ponta a ponta. Projetos medios ou grandes sao classificados antes da primeira rodada e divididos em fases. Ao fim de cada fase, a IA piloto salva um relatorio com escopo entregue, artefatos, validacao, falhas, consumo e proxima fase; em seguida, continua automaticamente sem exigir outro comando do usuario.

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
| Selecao automatica por fase | Health checks escolheram Gemini para planejamento, Laguna M.1 para implementacao e Nemotron Ultra para revisao; smoke MetaGPT automatico concluiu. | Validado |

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
| Media | Matriz por fase real | Executar tres rodadas comparaveis de implementacao e revisao antes de promover ou reordenar modelos/fallbacks. |

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
| Pesquisa | [Avaliacao de modelos 9Router para MetaGPT](docs/research/9ROUTER_METAGPT_MODEL_EVALUATION_2026-07-16.md) |
| Caso real | [Relatorio de pilotagem](docs/case-studies/RELATORIO_PILOTAGEM_METAGPT.md) |
| Caso real | [Plano de fase e importador](docs/case-studies/fase-2-shopee-pedidos-plan.md) |
| Caso real | [Validacao de frontend](docs/case-studies/metagpt-frontend-validation-2026-07-15.md) |
| Caso real | [Analise de fluxo de dados](docs/case-studies/analise-fluxo-importacao-dashboard-2026-07-15.md) |

## Status de distribuicao

O objetivo desta publicacao e permitir testes independentes por outros desenvolvedores. Resultados reproduziveis devem ser incorporados ao playbook e aos perfis antes de declarar uma versao estavel.

## Licenca

Licenca ainda nao definida. Antes de distribuicao publica ampla, inclua um arquivo `LICENSE` com a permissao de uso escolhida.
