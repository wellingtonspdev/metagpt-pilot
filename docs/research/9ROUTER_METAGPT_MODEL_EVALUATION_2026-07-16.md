# Avaliacao de Modelos 9Router para MetaGPT

Data: 2026-07-16

## Objetivo

Registrar os testes reais da instalacao local `MetaGPT -> 9Router -> provedores`, separar disponibilidade operacional de capacidade de modelo e propor perfis de selecao para uma futura atualizacao da skill `metagpt-pilot`.

Este documento **nao altera automaticamente** a skill. A matriz proposta precisa de validacao em fases reais de projeto antes de virar regra padrao.

## Escopo e metodo

### Teste local de disponibilidade

Cada rota exposta por `GET http://127.0.0.1:20128/v1/models` recebeu uma unica chamada sequencial a `POST /v1/chat/completions` com:

- mensagem: `Responda somente OK`;
- `max_tokens: 8`;
- `temperature: 0`;
- `stream: false`;
- chave local do 9Router, nunca exibida ou armazenada nos relatorios.

`WORKING` significa apenas que a rota retornou HTTP 200 nesta chamada curta. Nao prova qualidade, tool calling, JSON estruturado, contexto longo, estabilidade ou adequacao a MetaGPT.

Foi executado tambem um smoke test completo do MetaGPT com `gemini/gemini-3.1-flash-lite-preview`: o container terminou com codigo 0 e gravou requisito, PRD e artefatos. Os erros de renderizacao Mermaid/Puppeteer foram nao bloqueantes.

### Hierarquia de evidencia para recomendacoes

1. Teste local desta maquina: confirma rota, autenticacao e disponibilidade no momento do teste.
2. Benchmark independente: Artificial Analysis, quando disponivel.
3. Benchmark oficial do benchmark: SWE-bench explica o protocolo e limita comparacoes entre agentes.
4. Numero publicado pelo fabricante: util, mas marcado como evidencia de fornecedor.
5. Catalogo/telemetria do OpenRouter: contexto, recursos e saude operacional; nao substitui benchmark de qualidade.

## Resultado local: rotas diretas de provedores

| Modelo | Resultado | Latencia do smoke | Observacao |
| --- | --- | ---: | --- |
| `gemini/gemini-3.1-flash-lite-preview` | WORKING | 683 ms | Validado tambem no MetaGPT. |
| `gemini/gemma-4-31b-it` | WORKING | 874 ms | API de chat respondeu. |
| `nvidia/deepseek-ai/deepseek-v4-flash` | WORKING | 5.812 ms | API de chat respondeu. |
| `nvidia/deepseek-ai/deepseek-v4-pro` | WORKING | 763 ms | API de chat respondeu. |
| `nvidia/minimaxai/minimax-m2.7` | WORKING | 565 ms | API de chat respondeu. |
| `nvidia/z-ai/glm-5.2` | WORKING | 481 ms | API de chat respondeu. |
| `ollama/gpt-oss:120b` | WORKING | 638 ms | API de chat respondeu. |
| `ollama/minimax-m2.5` | WORKING | 646 ms | API de chat respondeu. |
| `ollama/minimax-m3` | WORKING | 927 ms | API de chat respondeu. |
| `gemini/gemini-3.1-pro-preview` | FAILED | 242 ms | HTTP 429: quota do provedor excedida. |
| `gemini/gemini-3-flash-preview` | FAILED | 30.021 ms | timeout local da chamada. |
| `nvidia/minimaxai/minimax-m3` | FAILED | 176 ms | HTTP 400: funcao upstream degradada. |
| `nvidia/moonshotai/kimi-k2.6` | FAILED | 197 ms | HTTP 404: funcao nao encontrada para a conta. |
| `nvidia/nemotron-3-ultra-550b-a55b` | FAILED | 160 ms | HTTP 404 no endpoint NVIDIA. |
| `nvidia/parakeet-ctc-1.1b-asr` | FAILED | 153 ms | Endpoint de ASR, nao rota de chat utilizavel. |
| `ollama/glm-4.7-flash` | FAILED | 322 ms | HTTP 404: modelo ausente. |
| `ollama/glm-5` | FAILED | 252 ms | HTTP 410: modelo aposentado. |
| `ollama/kimi-k2.5` | FAILED | 3.284 ms | HTTP 403: assinatura exigida. |
| `ollama/qwen3.5` | FAILED | 3.261 ms | HTTP 403: assinatura exigida. |
| `qd/ultimate` | FAILED | 30.014 ms | timeout local da chamada. |

## Resultado local: rotas OpenRouter

O identificador correto exige o prefixo `openrouter/`. Por exemplo, `qwen/qwen3-coder:free` falhou por nao existir uma credencial ativa para o provedor `qwen`; a rota correta e `openrouter/qwen/qwen3-coder:free`.

| Modelo | Resultado | Latencia do smoke | Observacao |
| --- | --- | ---: | --- |
| `openrouter/cohere/north-mini-code:free` | WORKING | 1.296 ms | Rota de chat respondeu. |
| `openrouter/google/gemma-4-26b-a4b-it:free` | WORKING | 575 ms | Rota de chat respondeu. |
| `openrouter/nvidia/nemotron-3-nano-30b-a3b:free` | WORKING | 557 ms | Rota de chat respondeu. |
| `openrouter/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` | WORKING | 638 ms | Rota de chat respondeu. |
| `openrouter/nvidia/nemotron-3-super-120b-a12b:free` | WORKING | 514 ms | Rota de chat respondeu. |
| `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | WORKING | 597 ms | Rota de chat respondeu. |
| `openrouter/poolside/laguna-m.1:free` | WORKING | 447 ms | Rota de chat respondeu. |
| `openrouter/poolside/laguna-xs-2.1:free` | WORKING | 288 ms | Rota de chat respondeu. |
| `openrouter/tencent/hy3:free` | WORKING | 1.819 ms | Rota de chat respondeu. |
| `openrouter/google/gemma-4-31b-it:free` | TEMPORARY_FAILURE | 693 ms | HTTP 429: rate limit upstream. |
| `openrouter/qwen/qwen3-coder:free` | TEMPORARY_FAILURE | 701 ms | HTTP 429: rate limit upstream. |
| `openrouter/qwen/qwen3-next-80b-a3b-instruct:free` | TEMPORARY_FAILURE | 694 ms | HTTP 429: rate limit upstream. |
| `openrouter/google/lyria-3-clip-preview` | FAILED | 26.881 ms | HTTP 502; modelo de audio, nao candidato MetaGPT. |
| `openrouter/google/lyria-3-pro-preview` | FAILED | 27.663 ms | HTTP 502; modelo de audio, nao candidato MetaGPT. |

Artefatos brutos sem segredos:

- `D:\MetaGPT\runs\session-2\artifacts\9router-model-smoke-20260716-165541.json`
- `D:\MetaGPT\runs\session-2\artifacts\9router-openrouter-model-smoke-20260716-170908.json`

## Leitura dos benchmarks e fontes

### Qualidade de avaliacao

SWE-bench Verified e um subconjunto de 500 tarefas verificadas por humanos. Ele avalia se patches resolvem problemas reais, mas a pontuacao depende do agente/harness; portanto, resultados de sistemas diferentes nao devem ser tratados como desempenho puro do modelo. O proprio leaderboard mantem uma configuracao bash-only para comparacao mais proxima entre LMs. Fonte: [SWE-bench Verified](https://www.swebench.com/verified.html).

Artificial Analysis e usado como fonte independente de comparacao de inteligencia, coding, agente e velocidade. Seus indices sao compostos e nao equivalem a garantia de um fluxo MetaGPT especifico.

### Evidencias relevantes para os modelos testados

| Modelo/linha | Evidencia | Interpretacao operacional |
| --- | --- | --- |
| `nvidia/deepseek-ai/deepseek-v4-flash` | Artificial Analysis informa indice de inteligencia 40, cerca de 103-111 tok/s e contexto de 1M. Tambem alerta que a variante de raciocinio e muito verbosa. [Fonte](https://artificialanalysis.ai/models/deepseek-v4-flash/) | Bom candidato para arquitetura, investigacao de bugs e contexto extenso, com teto de saida e prompt estrito para conter verbosidade. |
| `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | Artificial Analysis informa indice de inteligencia 38, contexto de 262K e mediana de 189,9 tok/s. [Fonte](https://artificialanalysis.ai/models/nvidia-nemotron-3-ultra-550b-a55b/) | Candidato forte para planejamento complexo e revisao de alto impacto, com boa velocidade. A rota NVIDIA direta falhou; usar somente a rota OpenRouter que passou. |
| `openrouter/cohere/north-mini-code:free` | Artificial Analysis mede indice de coding 33,4, indice de inteligencia 27,6 e aproximadamente 199 tok/s no teste de pre-lancamento; tambem registra desempenho agentic geral menor. [Fonte](https://artificialanalysis.ai/articles/north-mini-code-cohere-s-small-coding-focused-moe-model) | Bom candidato para edicoes de codigo localizadas, geracao estruturada e subagentes rapidos; nao usar como unico agente de arquitetura. |
| `openrouter/poolside/laguna-m.1:free` | OpenRouter declara modelo voltado a coding agent, tool calling, raciocinio, contexto 262K e saida de ate 32K. A pagina tambem mostra, no momento da consulta, 27,84% de erro medio de tool call para o provedor. [Fonte](https://openrouter.ai/poolside/laguna-m.1%3Afree/providers) | Candidato principal para implementacao agentic de codigo, mas deve ter fallback e testes de tools. A rota gratuita pode usar entradas/saidas para treinamento. |
| `openrouter/poolside/laguna-m.1:free` | A Poolside relata 46,9% no SWE-bench Pro e 40,7% no Terminal-Bench 2.0. Isto e evidencia de fornecedor, nao benchmark independente. [Fonte](https://poolside.ai/blog/laguna-a-deeper-dive) | Reforca a priorizacao em tarefas de repositorio e terminal, mas nao basta sozinho para promover o modelo a padrao sem experimento local. |
| `openrouter/poolside/laguna-xs-2.1:free` | Catalogo OpenRouter o descreve como coding agent menor com tool calling, raciocinio, contexto 256K e saida ate 32K. [Fonte](https://openrouter.ai/models?order=pricing-high-to-low&q=free) | Fallback de menor latencia para tarefas de codigo com escopo bem delimitado. Ainda sem evidencia independente especifica da versao 2.1 nesta pesquisa. |
| `gemini/gemini-3.1-flash-lite-preview` | Validado ponta a ponta nesta instalacao MetaGPT. A Google publica resultado MRCR medio de 60,1% em 128K, demonstrando que a janela nominal nao garante recuperacao perfeita em todo o contexto. [Fonte](https://deepmind.google/models/gemini/flash-lite/) | Perfil mais seguro ja validado para PRD e planejamento leve. Usar contexto selecionado, nao despejar repositorios inteiros. |

## Sintese: selecao proposta por cenario

As escolhas abaixo combinam disponibilidade local no momento, evidencia externa e adequacao ao tipo de fase. Sao hipoteses operacionais para experimento, nao afirmacoes de superioridade universal.

| Cenario MetaGPT | Primario proposto | Fallback | Motivo e guardas |
| --- | --- | --- | --- |
| PRD, escopo, historias de usuario e planejamento curto | `gemini/gemini-3.1-flash-lite-preview` | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | Gemini ja executou o fluxo MetaGPT local. Limitar contexto a requisitos e decisoes relevantes. |
| Arquitetura, decisao tecnica e investigacao de bug dificil | `nvidia/deepseek-ai/deepseek-v4-flash` | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | DeepSeek Flash tem evidencia independente de alta inteligencia e 1M de contexto, mas precisa de `max_token` menor por ser verbose. |
| Implementacao multiarquivo, terminal e testes de repositorio | `openrouter/poolside/laguna-m.1:free` | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | Laguna e especializado em coding agent; exigir checkpoint por fase, teste local e fallback por erro de tool call/429. |
| Edicao localizada, refatoracao pequena, schema e JSON | `openrouter/cohere/north-mini-code:free` | `openrouter/poolside/laguna-xs-2.1:free` | North Mini Code combina coding independente e alta velocidade; manter escopo pequeno por sua evidencia agentic geral mais baixa. |
| Revisao de codigo, diagnostico e segunda opiniao | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | `nvidia/deepseek-ai/deepseek-v4-flash` | Ambos responderam localmente; usar prompts de criterios objetivos e nao pedir reimplementacao completa. |
| Tarefa curta de alta vazao e baixo risco | `openrouter/poolside/laguna-xs-2.1:free` | `openrouter/cohere/north-mini-code:free` | Escolher somente depois de health check; ambos funcionaram no smoke, mas faltam testes MetaGPT completos. |

## Politica de roteamento recomendada para a skill

### Nao usar roteamento cego por catalogo

`/v1/models` mostrou modelos que retornaram 404, 403, 410 e 429. Antes de iniciar uma fase, a skill deve executar um health check de uma chamada curta no modelo escolhido e classificar:

- `healthy`: HTTP 200;
- `temporary_unavailable`: 429, timeout ou 5xx;
- `misconfigured`: 401, 403, 404, 410 ou 400 de funcao degradada;
- `incompatible`: audio, visao ou endpoint sem chat/tools para a fase.

### Selecionar por fase, depois aplicar fallback

1. Escolher o modelo primario pela tabela de cenario.
2. Fazer health check curto sem streaming.
3. Executar uma fase limitada com modelo explicitamente passado em `-Model`.
4. Em 429/timeout, registrar o evento e trocar somente para o fallback daquela fase.
5. Em erro de JSON/tool call, reduzir o escopo e tentar uma vez; nao repetir indefinidamente.
6. Ao final, registrar artefato, testes, latencia e motivo de fallback.

Nao usar trocas de chave para contornar limite. O fallback troca modelo/provedor por disponibilidade ou adequacao tecnica, nao burla cotas.

### Base cientifica para o desenho

FrugalGPT descreve cascatas de modelos para equilibrar qualidade e custo e relata que uma cascata pode igualar o melhor modelo com reducao de custo em seus experimentos. [Fonte](https://arxiv.org/abs/2305.05176)

RouteLLM propoe roteadores entre modelo forte e fraco treinados com preferencias e relata reducao de custo acima de 2x em seus benchmarks sem perda de qualidade. [Fonte](https://arxiv.org/abs/2406.18665)

Esses trabalhos justificam uma politica de roteamento; eles nao validam automaticamente a melhor combinacao para este 9Router. O mecanismo deve aprender com dados locais: fase, modelo, sucesso, erros, latencia, tokens e aprovacao dos testes.

## Experimentos necessarios antes de atualizar a skill

1. Executar a mesma fase de backend pequena com `Laguna M.1`, `North Mini Code`, `Nemotron Ultra` e `DeepSeek V4 Flash`.
2. Medir: artefatos aceitos, testes aprovados, chamadas, latencia, falhas de JSON/tool, tamanho de diff e necessidade de reparo humano.
3. Rodar ao menos tres repeticoes por perfil, pois rotas gratuitas oscilam.
4. Separar qualidade de codigo de disponibilidade: um modelo pode ser excelente e estar indisponivel por 429.
5. Atualizar a skill somente com regras condicionais, fallbacks limitados e fatos comprovados pelos experimentos.

## Conclusao atual

O 9Router esta funcional e oferece rotas OpenRouter utilizaveis. A melhor escolha inicial nao e um unico modelo global:

- `gemini/gemini-3.1-flash-lite-preview` e a opcao mais comprovada para iniciar MetaGPT nesta maquina.
- `openrouter/poolside/laguna-m.1:free` e o principal candidato para fases de implementacao, sujeito a teste agentic local e fallback.
- `openrouter/cohere/north-mini-code:free` e indicado para subtarefas de codigo curtas e rapidas.
- `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` e o fallback forte para raciocinio e revisao.
- `nvidia/deepseek-ai/deepseek-v4-flash` e candidato para analise complexa e grande contexto, com controle de verbosidade.

Nenhuma dessas recomendacoes substitui validacao de testes do projeto. O modelo deve ser escolhido explicitamente por `-Model` em cada execucao ate que a matriz seja validada por experimentos controlados.

## Experimento de automacao da selecao

Em 2026-07-16, o seletor foi implementado e testado contra o 9Router local. Health checks selecionaram:

| Rota | Modelo selecionado | Resultado do health check |
| --- | --- | --- |
| Planning | `gemini/gemini-3.1-flash-lite-preview` | HTTP 200, 699 ms |
| Implementation | `openrouter/poolside/laguna-m.1:free` | HTTP 200, 1.423 ms |
| Review | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | HTTP 200, 560 ms |

O launcher da sessao 2 foi executado com `-Model Auto`, `-SelectionPhase Planning` e papel `Product Manager`. Ele registrou no manifesto o modelo Gemini, a rota `Planning`, o motivo e os fallbacks; a rodada MetaGPT gerou requisito e PRD e encerrou com codigo 0.

O experimento confirma o mecanismo de selecao e auditoria. Ainda nao confirma que Laguna M.1 e Nemotron Ultra superam alternativas em fases completas de implementacao/revisao; isso permanece no plano de experimentos.

## Experimento de gerenciamento de catalogo

O seletor passou a consultar o catalogo antes de cada rodada e a comparar os IDs com um registro versionado de evidencias. No snapshot de 2026-07-16 foram observados 34 modelos, seis candidatos habilitados pela matriz e 23 modelos nao revisados. Os nao revisados foram registrados no manifesto, mas nao entraram no roteamento automatico.

Foi validada tambem a classificacao por papel e atividade:

| Entrada | Rota derivada | Modelo selecionado |
| --- | --- | --- |
| Engineer, implementacao de endpoint, migracao e testes, alta complexidade | `Implementation` | `openrouter/poolside/laguna-m.1:free` |
| QA, revisao de regressao e diagnostico de falha, alta complexidade | `Review` | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` |

O registro nao promove modelos novos automaticamente. A promocao exige pesquisa de fontes oficiais e independentes, seguida de tres rodadas comparaveis com artefatos e testes aprovados.

## Revisao dos 23 modelos pendentes do catalogo

Em 2026-07-16, os 23 IDs que estavam presentes no catalogo do 9Router e ausentes do registro foram classificados. A revisao combina o smoke local ja arquivado, documentacao primaria e, quando disponivel, Artificial Analysis. O status `candidate` nao habilita roteamento: ele apenas identifica uma rota que pode entrar no proximo experimento controlado.

| Modelo | Teste local | Evidencia externa | Decisao para MetaGPT |
| --- | --- | --- | --- |
| `gemini/gemini-3.1-pro-preview` | HTTP 429 | A pagina e o model card da Google declaram 1M de entrada, 64K de saida, function calling, structured output, code execution e foco em agentic/coding. [Fonte](https://deepmind.google/models/gemini/pro/) | `temporary_unavailable`; nao pode ser selecionado ate a quota responder. |
| `gemini/gemini-3-flash-preview` | timeout em 30 s | A Google posiciona Gemini 3 Flash para fluxos agentic e multimodais de baixa latencia. [Fonte](https://deepmind.google/technologies/gemini/flash/) | `temporary_unavailable`; retestar com timeout curto antes de fase real. |
| `gemini/gemma-4-31b-it` | WORKING | A Google oferece `gemma-4-31b-it` na Gemini API; a avaliacao independente lista indice de inteligencia 29 para a variante de raciocinio. [Fontes](https://ai.google.dev/gemma/docs/core/gemma_on_gemini_api) e [Artificial Analysis](https://artificialanalysis.ai/models/gemma-4-31b/). | `candidate`; bom para teste de tarefa delimitada, ainda sem fase MetaGPT. |
| `nvidia/deepseek-ai/deepseek-v4-pro` | WORKING | Artificial Analysis informa indice 41 e contexto de 1M para a rota Pro; o resultado depende da configuracao de esforco e do provedor. [Fonte](https://artificialanalysis.ai/models/deepseek-v4-pro-high/) | `candidate`; comparar contra DeepSeek Flash em arquitetura/revisao com teto de saida. |
| `nvidia/minimaxai/minimax-m2.7` | WORKING | Artificial Analysis lista indice 38 para M2.7; a comparacao publicada usa um indice composto que inclui Terminal-Bench, SciCode e outros testes. [Fontes](https://artificialanalysis.ai/models/minimax-m2-7) e [metodologia](https://artificialanalysis.ai/models/comparisons/glm-5-2-vs-minimax-m2-7). | `candidate`; exigir JSON e testes de fase antes de rota automatica. |
| `nvidia/minimaxai/minimax-m3` | HTTP 400, funcao degradada | A familia tem evidencia externa, mas a funcao da conta estava degradada. | `misconfigured`; nao testar novamente ate o health check recuperar. |
| `nvidia/moonshotai/kimi-k2.6` | HTTP 404 | A comparacao independente posiciona K2.6 acima de K2.5 em indice atual, mas isso nao corrige a ausencia da funcao no provedor conectado. [Fonte](https://artificialanalysis.ai/models/comparisons/kimi-k2-6-vs-kimi-k2-5) | `misconfigured`; requer correcao no provedor, nao troca de chave. |
| `nvidia/nemotron-3-ultra-550b-a55b` | HTTP 404 | O modelo possui evidencia independente, mas somente o alias OpenRouter passou localmente. | `misconfigured`; usar exclusivamente `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free`. |
| `nvidia/parakeet-ctc-1.1b-asr` | HTTP 404 no chat | A NVIDIA documenta Parakeet CTC 1.1B como ASR, isto e, transcricao de fala para texto. [Fonte](https://docs.nvidia.com/nemo/speech/nightly/asr/asr_checkpoints.html) | `incompatible`; nao e modelo de chat/codigo para MetaGPT. |
| `nvidia/z-ai/glm-5.2` | WORKING | Artificial Analysis o descreve como lider open-weight em sua avaliacao da epoca e registra contexto de 1M; a analise tambem alerta para saidas muito longas em tarefas. [Fonte](https://artificialanalysis.ai/articles/glm-5-2-is-the-new-leading-open-weights-model-on-the-artificial-analysis-intelligence-index/) | `candidate`; testar somente com orcamento de saida e criterios objetivos. |
| `ollama/glm-4.7-flash` | HTTP 404 | Nao ha modelo servido nessa rota local. | `misconfigured`; remover ou corrigir o catalogo do provedor. |
| `ollama/glm-5` | HTTP 410 | O proprio provedor informou aposentadoria em 2026-07-15. | `retired`; nao usar. |
| `ollama/gpt-oss:120b` | WORKING | A documentacao da OpenAI confirma function calling e structured outputs para gpt-oss-120b. [Fonte](https://developers.openai.com/api/docs/models/gpt-oss-120b) | `candidate`; adequado para experimento de JSON/tools na rota Ollama. |
| `ollama/kimi-k2.5` | HTTP 403 | O modelo exige assinatura no provedor conectado. | `subscription_required`; nao selecionar enquanto indisponivel. |
| `ollama/minimax-m2.5` | WORKING | A pagina do provedor Artificial Analysis permite comparar M2.5, M2.7 e M3, mas resultados podem variar por versao/effort. [Fonte](https://artificialanalysis.ai/providers/minimax) | `candidate`; usar apenas em comparativo com M2.7/M3, nao como fallback padrao. |
| `ollama/minimax-m3` | WORKING | A mesma fonte aponta melhoria da familia M3, mas o teste local ainda foi apenas chat curto. [Fonte](https://artificialanalysis.ai/providers/minimax) | `candidate`; comparar com M2.7 em fase identica. |
| `ollama/qwen3.5` | HTTP 403 | O modelo exige assinatura no provedor conectado. | `subscription_required`; nao selecionar enquanto indisponivel. |
| `openrouter/google/gemma-4-31b-it:free` | HTTP 429 | O modelo e oficialmente hospedado pela Gemini API e tem dados independentes, mas a rota gratuita estava limitada. | `temporary_unavailable`; o alias direto Gemini e o caminho de teste atual. |
| `openrouter/google/lyria-3-clip-preview` | HTTP 502 | Lyria 3 gera musica a partir de texto, com saida de audio e letras. [Fonte](https://deepmind.google/models/model-cards/lyria-3/) | `incompatible`; nao e agente textual MetaGPT. |
| `openrouter/google/lyria-3-pro-preview` | HTTP 502 | Mesma familia de geracao de musica. [Fonte](https://deepmind.google/models/lyria/) | `incompatible`; nao e agente textual MetaGPT. |
| `openrouter/qwen/qwen3-coder:free` | HTTP 429 | Qwen descreve Qwen3-Coder 480B-A35B como modelo para coding, tools e agentes, com 256K nativo e 1M por extrapolacao. [Fonte](https://qwenlm.github.io/blog/qwen3-coder/) | `temporary_unavailable`; candidato forte para implementacao apos a rota gratuita estabilizar e passar tres fases. |
| `openrouter/qwen/qwen3-next-80b-a3b-instruct:free` | HTTP 429 | Artificial Analysis registra 262K de contexto e alta velocidade, mas como variante instrutiva nao focada em coding agent. [Fonte](https://artificialanalysis.ai/models/qwen3-next-80b-a3b-instruct/) | `temporary_unavailable`; reavaliar para tarefas gerais e rapidas, nao promover para implementacao. |
| `qd/ultimate` | timeout em 30 s | Nao foi encontrada documentacao primaria verificavel nem resposta de chat. | `unresolved`; manter fora da matriz ate haver fornecedor, modalidade e health check claros. |

### Resultado da revisao

- Foram resolvidos os 23 itens pendentes do catalogo: sete viraram `candidate`, cinco ficaram `temporary_unavailable`, seis `misconfigured` ou `subscription_required`, tres `incompatible`, um `retired` e um `unresolved`.
- Nenhum candidato foi habilitado. A regra continua sendo tres fases comparaveis, com testes aprovados e sem falha recorrente de JSON/tools, antes de alterar prioridades.
- Os modelos ja habilitados continuam sendo os seis que ja tinham smoke local e justificativa de rota. O catalogo deixa de confundir modelos de audio, rotas retiradas e modelos apenas listados com alternativas utilizaveis pelo MetaGPT.

