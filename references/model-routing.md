# Selecao Automatizada de Modelos

## Limite do MetaGPT

O MetaGPT configura um modelo por container/rodada. Ele nao troca de modelo entre papeis de uma equipe ja em execucao. Para especializar por papel, dividir o projeto em rodadas/fases pequenas e selecionar o modelo antes de iniciar cada rodada.

## Seletor operacional

Usar `scripts/select-metagpt-model.ps1` com a chave local do proxy, base URL, fase, papel, tarefa e complexidade. O seletor:

1. Consulta `/v1/models`.
2. Classifica a rodada em `Planning`, `Architecture`, `Implementation`, `Review` ou `Fast`.
3. Considera somente modelos presentes no catalogo atual.
4. Faz no maximo dois health checks de 8 tokens, sequenciais e sem streaming.
5. Retorna JSON com modelo selecionado, fallbacks e resultado dos probes.

Nao registrar `ApiKey`, headers ou prompts completos. O modelo explicito passado pelo usuario sempre vence a selecao automatica.

## Matriz inicial validada em 2026-07-16

| Rota | Primario | Fallbacks | Base |
| --- | --- | --- | --- |
| Planning | `gemini/gemini-3.1-flash-lite-preview` | Nemotron Ultra, North Mini Code | Smoke MetaGPT local concluido. |
| Architecture | `nvidia/deepseek-ai/deepseek-v4-flash` | Nemotron Ultra, Gemini Flash Lite | Benchmark independente de alta inteligencia/contexto; limitar saida por verbosidade. |
| Implementation | `openrouter/poolside/laguna-m.1:free` | North Mini Code, Nemotron Ultra, DeepSeek V4 Flash | Especializacao coding agent; manter fallback por oscilacao de tools/free tier. |
| Review | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | DeepSeek V4 Flash, North Mini Code | Raciocinio e velocidade independentes; usar criterios objetivos. |
| Fast | `openrouter/cohere/north-mini-code:free` | Laguna XS 2.1, Gemini Flash Lite | Coding e velocidade para subtarefas pequenas. |

As rotas foram escolhidas a partir do relatorio local `D:\MetaGPT\docs\9ROUTER_METAGPT_MODEL_EVALUATION_2026-07-16.md`. Elas sao hipoteses operacionais. Atualizar apenas depois de registrar resultado de fase real em `experience-log.md`.

## Falha e fallback

- `429`, timeout e 5xx: classificar como temporario; parar a rodada atual, preservar artefatos e chamar o seletor com o modelo falho em `-ExcludeModels`.
- `400`, `401`, `403`, `404` e `410`: classificar como configuracao, modelo retirado ou incompatibilidade; excluir o modelo ate nova validacao.
- JSON invalido ou tool-call falho: reduzir escopo; trocar para fallback somente apos uma recuperacao limitada do perfil P2/P3.
- Nao trocar chaves para contornar cotas. Nao testar todos os modelos antes de cada fase.

## Aprendizado controlado

Registrar por rodada: rota, modelo, papel/fase, complexidade, probes, artefato, testes, latencia, falha e fallback. Promover uma alteracao da matriz somente apos tres rodadas comparaveis e criterios de aceite aprovados.
