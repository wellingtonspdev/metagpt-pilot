# Pesquisa de Fontes: Otimizacao de Tokens e Confiabilidade de Agentes

Data da coleta: 2026-07-14.

Este documento e um catalogo de evidencia para a proxima sintese. Ele nao altera configuracoes nem declara uma receita final.

## Perguntas de pesquisa

1. Como controlar aleatoriedade sem aumentar alucinacao ou repeticao?
2. Quando dividir, resumir ou comprimir contexto?
3. Quando reflexao, revisao e multiagente melhoram a qualidade e quando apenas consomem tokens?
4. Quais limites de parada evitam loops, retries improdutivos e crescimento de contexto?
5. Quais controles ja existem no MetaGPT oficial e qual e sua semantica?

## Fontes primarias e revisadas por pares

| Fonte | Nivel | Evidencia relevante | Aplicabilidade a MetaGPT |
|---|---|---|---|
| [ReAct: Synergizing Reasoning and Acting in Language Models](https://arxiv.org/abs/2210.03629) - Yao et al., ICLR 2023 | Conferencia revisada | Intercalar raciocinio com observacoes/acoes ajuda o agente a atualizar planos e lidar com excecoes. | Usar verificacoes por ferramenta/teste entre etapas de implementacao, em vez de longos monologos de planejamento. |
| [Reflexion: Language Agents with Verbal Reinforcement Learning](https://arxiv.org/abs/2303.11366) - Shinn et al., NeurIPS 2023 | Conferencia revisada | Feedback textual e memoria episodica podem melhorar agentes de codigo e decisao sem treinar pesos. | Registrar uma reflexao curta, baseada no erro real, antes de uma nova tentativa; nunca refletir indefinidamente. |
| [Self-Refine: Iterative Refinement with Self-Feedback](https://papers.neurips.cc/paper_files/paper/2023/hash/91edff07232fb1b55a505a9e9f6c0ff3-Abstract-Conference.html) - Madaan et al., NeurIPS 2023 | Conferencia revisada | Refinamento iterativo melhorou resultados avaliados, mas cada ciclo adiciona custo. | Limitar revisao a uma ou duas passagens e exigir criterio verificavel de melhoria. |
| [The Effect of Sampling Temperature on Problem Solving in LLMs](https://arxiv.org/abs/2402.05201) - Renze e Guven, 2024 | Preprint empirico | Nos testes dos autores, variar temperatura de 0 a 1 nao teve efeito estatisticamente significativo em problemas MCQA. | Nao tratar temperatura como botao magico de qualidade; medir por tipo de acao e modelo. |
| [Large Language Models have Intrinsic Self-Correction](https://arxiv.org/abs/2406.15673) - Huang et al., 2024 | Preprint empirico | Reporta que maior temperatura pode prejudicar a autocorrecao; prompts sem vies e temperatura baixa favorecem esse mecanismo no estudo. | Manter baixa aleatoriedade em JSON, codigo, revisao e correcoes; testar criatividade separadamente. |

## Fontes sobre contexto e compressao

| Fonte | Nivel | Evidencia relevante | Cuidado para a sintese |
|---|---|---|---|
| [LLMLingua](https://arxiv.org/abs/2310.05736) - Jiang et al., 2023 | Preprint | Propoe compressao com controlador de orcamento; reporta ate 20x com pouca perda nos conjuntos avaliados. | Nao comprimir especificacao autoritativa, contratos de API, erros ou trechos de codigo necessarios; comprimir historico redundante. |
| [LLMLingua-2](https://arxiv.org/abs/2403.12968) - Pan et al., 2024 | Preprint | Compressao extrativa treinada para fidelidade; reporta reducao de latencia com ratios 2x-5x. | Avaliar compressao por fase e comparar contra teste/artefato, nao apenas semelhanca semantica. |
| [MemGPT](https://arxiv.org/abs/2310.08560) - Packer et al., 2023 | Preprint | Gerencia memoria em camadas e usa contexto virtual para documentos/conversas longos. | Separar memoria duravel (requisitos, decisoes, estado) do contexto de trabalho curto. |
| [Prompt Compression in the Wild](https://arxiv.org/abs/2604.02985) - Kummer et al., 2026 | Preprint recente | Mostra que a compressao so compensa quando tamanho, hardware e razao de compressao estao na faixa adequada; fora dela, preprocessamento pode anular ganho. | Medir antes de habilitar compressao adicional no MetaGPT. |

## Fontes sobre raciocinio conciso, orcamento e parada

| Fonte | Nivel | Evidencia relevante | Aplicabilidade a MetaGPT |
|---|---|---|---|
| [Chain of Draft](https://arxiv.org/abs/2502.18600) - Xu et al., 2025 | Preprint | Raciocinio intermediario conciso igualou/superou CoT nos testes relatados usando ate 7,6% dos tokens. | Pedir planos, diagnosticos e reflexoes em formato curto, com fatos e proxima acao, nao cadeias narrativas extensas. |
| [Efficient Agents](https://arxiv.org/abs/2508.02694) - Wang et al., 2025 | Preprint empirico | Estuda relacao custo-efetividade e retornos decrescentes de modulos; reporta 28,4% de melhoria em custo por sucesso no benchmark usado. | Escalar numero de agentes, revisoes e testes para o risco da fase; nao ativar todos em toda tarefa. |
| [Token Budgets](https://arxiv.org/abs/2606.04056) - Khan, 2026 | Preprint recente | Catalogo de incidentes de estouro de orcamento; destaca retries e fan-out como fontes de sobreconsumo. | Implementar limite por fase, por tentativa e por execucao; registrar gasto estimado e bloquear novas tentativas sem novo sinal. |
| [When Agents Do Not Stop](https://arxiv.org/abs/2607.01641) - Hou et al., 2026 | Preprint recente | Analisa loops de agentes que alcançam chamadas caras sem limite efetivo. | Criar criterios de parada para repeticao, invalidez consecutiva e ausencia de novos artefatos. |
| [MIRAI](https://arxiv.org/abs/2407.01231) - Xue et al., 2024 | Preprint | Usa criterios de parada por resposta final, acoes invalidas consecutivas, acoes repetitivas consecutivas ou maximo de iteracoes. | Base concreta para definir guardrails no piloto MetaGPT. |

## Fontes sobre multiagente

| Fonte | Nivel | Evidencia relevante | Aplicabilidade a MetaGPT |
|---|---|---|---|
| [Self-Resource Allocation in Multi-Agent LLM Systems](https://arxiv.org/abs/2504.02051) - Amayuelas et al., 2025 | Preprint | O estudo relata melhor eficiencia do planejamento para acoes concorrentes e ganho ao explicitar capacidades dos workers. | Definir papel, entrada, saida, criterio de aceite e limite de cada agente antes de iniciar uma fase. |
| [Efficient Agents](https://arxiv.org/abs/2508.02694) - Wang et al., 2025 | Preprint empirico | Mostra que mais modulos e escalonamento de inferencia possuem trade-off de custo e retorno. | Manter conjunto completo de papeis para marcos; usar fluxo reduzido em correcoes pequenas. |

## Evidencia do MetaGPT instalado

A inspecao local da versao oficial em `D:\MetaGPT` encontrou:

- `metagpt/configs/llm_config.py`: defaults `max_token=4096`, `temperature=0.0`, `top_p=1.0`, `compress_type=NO_COMPRESS` e `reasoning_max_token=4000`.
- `metagpt/config2.py`: `repair_llm_output` e `code_validate_k_times` sao configuraveis.
- `metagpt/utils/repair_llm_raw_output.py`: com reparo ativado, ha combinacao de tentativas que pode multiplicar chamadas; o piloto confirmou que isso deve ter limite externo.
- `metagpt/team.py`: `n_round` controla rodadas da simulacao, nao e garantia de conclusao do MVP.
- `metagpt/provider/base_llm.py`: ha modos de truncamento de mensagens por token ou mensagem; truncamento pode remover contexto critico se usado sem memoria estruturada.

Documentacao oficial complementar:

- [Configuracao de LLM do MetaGPT](https://docs.deepwisdom.ai/main/en/guide/get_started/configuration/llm_api_configuration.html)
- [FAQ oficial: significado de max token](https://github.com/FoundationAgents/MetaGPT/blob/main/docs/FAQ-EN.md)
- [Repositorio oficial MetaGPT](https://github.com/FoundationAgents/MetaGPT)

## Proximas perguntas para a sintese

1. Quais perfis de configuracao devem existir: planejamento, JSON estruturado, implementacao, revisao, teste e recuperacao?
2. Quais limites externos devem interromper um container antes de exaurir a quota diaria?
3. Quais campos devem compor uma memoria de fase curta e quais devem permanecer em documentos duraveis?
4. Quais ajustes sao possiveis apenas por YAML/launcher e quais exigiriam uma extensao externa ao MetaGPT?
5. Qual experimento controlado validara cada perfil com o mesmo projeto e criterio de aceite?
