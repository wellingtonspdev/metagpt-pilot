# Fluxo Autonomo de Projeto

## Finalidade

Este fluxo e usado quando o operador pede que uma IA pilote o MetaGPT do inicio ao fim a partir de `agents.md` ou `AGENTS.md`. A IA piloto nao deve delegar a responsabilidade ao usuario depois de cada rodada. Ela planeja, executa, monitora, recupera e valida cada fase com base na especificacao autoritativa.

## Entrada minima

1. Diretorio do projeto exclusivo da sessao.
2. `agents.md` ou `AGENTS.md` com objetivo, stack, escopo, restricoes e criterios de aceite.
3. Perfil inicial, modelo, orcamento da sessao e criterio de parada.
4. Chave fornecida apenas por variavel de ambiente local.

## Ciclo obrigatorio

1. Ler a especificacao e criar `SPEC.md` imutavel, `STATE.md`, `DECISIONS.md` e `HANDOFF.md` curtos no projeto ou no diretorio de sessao.
2. Mapear o estado atual do repositorio e registrar os artefatos existentes, testes e Git antes da primeira chamada.
3. Converter o projeto em fases com entregas observaveis e criterios de aceite. Comecar por planejamento de uma fase, nunca por um MVP monolitico.
4. Para cada fase: selecionar perfil, injetar somente o contexto necessario, iniciar a rodada, monitorar container, arquivos e testes.
5. Quando houver falha reproduzivel, tentar a recuperacao descrita no playbook: corrigir escopo, dividir a tarefa, reaproveitar artefatos e testar. Nao repetir o mesmo prompt/modelo em loop.
6. Ao finalizar uma fase, validar criterios de aceite, testes, build e estado Git; atualizar `STATE.md` e `HANDOFF.md`; iniciar a proxima fase sem pedir confirmacao operacional.
7. Ao finalizar todas as fases, executar validacao integrada, documentar resultado, registrar pendencias reais e encerrar com `COMPLETED` ou motivo padronizado.

## Quando continuar sem perguntar

Continuar autonomamente quando a proxima acao for reversivel e sustentada por `agents.md`, estado do projeto, testes ou playbook: dividir tarefa, corrigir bug, retomar container, trocar para fallback permitido, executar teste, ajustar documento ou registrar uma premissa menor.

## Quando parar e informar claramente

Parar somente quando ocorrer uma das condicoes abaixo:

| Codigo | Condicao |
| --- | --- |
| `PROJECT_DECISION_REQUIRED` | Decisao material de produto, arquitetura, seguranca, dados ou acao irreversivel nao esta definida na especificacao. |
| `NO_SAFE_SOLUTION_FOUND` | A falha foi reproduzida, as recuperacoes permitidas foram tentadas e nao ha proxima acao tecnica segura ou verificavel. |
| `UPSTREAM_RATE_LIMIT` | O provedor continua bloqueando apos o unico backoff/retry permitido. |
| `STRUCTURED_OUTPUT_FAILURE` | Tres reparos ou tentativas com novo escopo/modelo falharam para a mesma saida estruturada. |
| `BUDGET_GUARD_REACHED` | O orcamento monitorado atingiu 95%; nao iniciar nova chamada. |
| `COMPLETED` | Todos os criterios de aceite e validacoes acordados foram concluidos. |

O relatorio de parada deve conter: ultimo artefato valido, fase, teste executado, erro, tentativas feitas, consumo observado e proxima acao segura.

## Regra do limite de 5%

O limite deve ser definido como **orcamento observavel** antes da rodada: credito, chamadas permitidas pelo launcher, custo maximo ou franquia que a ferramenta consiga medir. Ao atingir 95% desse orcamento, a IA deve salvar o estado e parar antes da proxima chamada.

Nao afirmar que o limite diario gratuito do provedor esta a 5% se a telemetria nao expuser o numero de requisicoes restantes. Para OpenRouter, `GET /api/v1/key` permite consultar informacoes de credito e uso da chave, mas a franquia de modelos gratuitos e governada por regras de capacidade globais; nesse caso use um orcamento local conservador por sessao e trate erros de provedor como autoridade final.

## Exemplo de instrucao para a IA piloto

```text
Use $metagpt-pilot em modo autonomo controlado para este projeto.
Leia agents.md como fonte autoritativa. Trabalhe fase por fase, valide cada entrega,
recupere falhas dentro do playbook e continue sem perguntar por decisoes operacionais.
Pare apenas por decisao material ausente, ausencia de solucao segura ou quando o
orcamento observavel atingir 95%. Em qualquer parada, gere um relatorio explicito.
```
