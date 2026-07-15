# Playbook de falhas MetaGPT

## Decisao rapida

| Sinal | Acao |
|---|---|
| Nenhum arquivo de especificacao no prompt | Parar antes da primeira chamada; injetar a especificacao integralmente |
| 400 de contexto/saida | Reduzir `max_token`; considerar entrada mais curta |
| 429 com `Retry-After` | Esperar o intervalo e tentar uma vez; depois trocar modelo ou aguardar |
| Tres reparos JSON invalidos | Parar; arquivar estado; nao repetir o mesmo modelo/estagio |
| Mesmo texto repetido sem arquivos | Parar por loop improdutivo |
| Mermaid Chromium root/no-sandbox | Preservar `.mmd`; tratar como nao bloqueante |
| Repositorio reestruturado | Restaurar snapshot e usar especificacao externa imutavel |
| Importacao conclui com zero registros normalizados | Inspecionar aba, cabecalhos e contadores; classificar arquivo sem linhas como estado de dados, nao como defeito de UI ou LLM |
| Dois containers escrevendo no mesmo projeto ou usando o mesmo config runtime | Parar a nova sessao antes de gerar artefatos; separar projeto, container e `runtime/config2.yaml` |
| Duas sessoes recebem 429/ResourceExhausted no mesmo provedor | Pausar novas rodadas pesadas no provedor afetado; respeitar `Retry-After`; nao alternar chaves para contornar o limite |

## Aprendizados confirmados em 2026-07-14

- O MetaGPT oficial nao le arquivos de requisitos montados de forma confiavel; injete o conteudo.
- O fluxo `WriteCodePlanAndChange` pode exigir JSON grande demais para modelos gratuitos.
- North Mini Code e Nemotron 3 Ultra falharam por JSON invalido nesse estagio.
- Qwen3 Coder pode receber rate limit temporario de provedor; respeitar o intervalo e nao insistir em loop.
- O fallback `models` da OpenRouter precisa ser suportado pelo cliente; lista local no YAML nao garante fallback do MetaGPT.
- Usar MetaGPT para planejamento e fases curtas; implementar e testar em unidades menores quando a serializacao falhar.
- Em fluxos de planilha, validar a cadeia arquivo -> lote -> dados normalizados -> endpoint agregado -> UI antes de concluir que um dashboard esta incorreto.
- O template da sessao 2 separa config, container, logs e snapshots e recebe a chave somente por variavel de ambiente. A execucao paralela real ainda precisa de validacao controlada.
