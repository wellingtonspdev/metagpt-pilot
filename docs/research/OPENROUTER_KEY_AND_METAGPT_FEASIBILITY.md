# Viabilidade: MetaGPT e gerenciamento de chaves OpenRouter

Data da analise: 2026-07-14.

## Conclusao executiva

Nao e viavel nem apropriado implementar rotacao automatica de varias chaves ou contas OpenRouter para ampliar a franquia gratuita. A documentacao oficial informa expressamente que contas e chaves adicionais nao alteram os limites, pois a capacidade e governada globalmente.

O mecanismo recomendado para continuidade e: uma chave de inferencia por ambiente, retentativa com backoff e `Retry-After`, verificacao proativa de saldo/uso e fallback entre modelos. Para mais capacidade, usar credito pago, um provedor proprio via BYOK ou um modelo pago.

## Evidencias oficiais

1. Limites: https://openrouter.ai/docs/api_reference/limits
   - Chaves ou contas adicionais nao aumentam rate limits.
   - `GET /api/v1/key` mostra uso e limites de credito por chave.
   - Erros 429 podem ser limite da plataforma ou indisponibilidade do provedor; o cliente deve respeitar `Retry-After` e aplicar backoff exponencial.
   - A propria documentacao recomenda fallback de modelos quando um provedor esta sem capacidade.
2. Fallback de modelos: https://openrouter.ai/docs/guides/routing/model-fallbacks
   - O parametro `models` aceita uma lista ordenada e tenta o proximo modelo quando o anterior falha por rate limit, indisponibilidade ou outro erro.
3. Management API keys: https://openrouter.ai/docs/guides/overview/auth/management-api-keys
   - Chaves de gerenciamento servem para rotacao de seguranca, distribuicao por cliente e limites de gasto por chave.
   - Elas nao podem fazer chamadas de inferencia e nao devem ser usadas pelo MetaGPT.

## Decisao de seguranca

Nao implementar pool de chaves para contornar quota. Alem de nao resolver o limite global, isso pode violar regras do provedor e deixa varios segredos expostos na maquina.

Rotacao de chave e aceitavel somente para seguranca, revogacao, separacao de ambientes ou controle de gasto. A chave antiga deve ser revogada apos a substituicao e nunca deve entrar em commits, logs ou arquivos distribuidos.

## Arquitetura recomendada

1. Manter uma unica chave de inferencia em segredo local por ambiente.
2. Antes de rodadas longas, consultar `GET /api/v1/key` localmente sem registrar o segredo.
3. Em 429 de provedor, aguardar `Retry-After`; se indisponibilidade persistir, trocar de modelo, nao de chave.
4. Usar uma ordem de fallback por capacidade e compatibilidade de JSON estruturado.
5. Quando atingir o limite diario da plataforma, encerrar com estado claro: `DAILY_QUOTA_EXHAUSTED`, ultimo erro, proxima acao e artefatos preservados.
6. Para aumentar capacidade de forma compativel: adicionar creditos na mesma conta, usar variante paga ou configurar BYOK de um provedor contratado.

## Resultado do piloto MetaGPT

O MetaGPT oficial executou corretamente os papeis de produto, arquitetura e planejamento, e preservou PRD, desenho do sistema e tarefas. A implementacao nao iniciou porque o estagio `WriteCodePlanAndChange` exige uma unica resposta JSON muito grande. Os modelos gratuitos testados retornaram JSON invalido nesse contrato:

- Cohere North Mini Code: JSON invalido entre as etapas de arquitetura, planejamento e plano de alteracao.
- Qwen3 Coder: rate limit temporario do provedor Venice, mesmo apos o intervalo solicitado.
- Nemotron 3 Ultra: JSON invalido no plano de alteracao de codigo apos aproximadamente 73 mil caracteres.

Portanto, o caminho mais confiavel e usar o MetaGPT para gerar e revisar os artefatos multiagente, e usar um agente de codigo com contexto persistente para a implementacao em fases menores. Retomar o MetaGPT somente quando houver um modelo que cumpra de forma consistente o contrato JSON estruturado ou quando a fase de codigo for particionada fora do fluxo padrao.
