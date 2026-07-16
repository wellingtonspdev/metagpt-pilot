---
name: metagpt-pilot
description: Pilotar execucoes oficiais do MetaGPT em Docker/OpenRouter com monitoramento, preservacao de workspace, recuperacao de falhas e controle de quota. Use ao iniciar, acompanhar, retomar, diagnosticar ou encerrar um projeto MetaGPT, especialmente quando houver agents.md, modelos gratuitos, 429, JSONDecodeError ou necessidade de economizar tokens.
---

# Pilotagem MetaGPT

Execute o MetaGPT oficial sem alterar o codigo-fonte. Use esta skill para transformar um pedido amplo em execucoes pequenas, observaveis e recuperaveis.

## Como usar

1. Para iniciar um projeto na pasta atual: `Use $metagpt-pilot`.
2. Para iniciar outro projeto: `Use $metagpt-pilot para iniciar o projeto em <caminho>`.
3. No Gemini ou Antigravity, substitua por: `Use a skill metagpt-pilot para iniciar o projeto em <caminho>`.
4. Descobrir automaticamente `agents.md` ou `AGENTS.md`, classificar o escopo e iniciar o modo autonomo controlado. Selecionar o modelo automaticamente por rodada a partir de fase, papel, tarefa, complexidade, catalogo do proxy e health check; nao pedir modelo, perfil, prompt de fase, container ou proxima etapa ao usuario.
5. Para retomar ou diagnosticar uma execucao existente, informar o ultimo container, log ou diretorio de artefatos. A skill deve verificar o estado antes de reiniciar.
6. Ler `references/universal-invocation.md` antes do primeiro projeto e `references/parallel-sessions.md` antes da segunda sessao.

Exemplos:

```text
Use $metagpt-pilot para executar uma fase de importacao de planilhas em D:\MeuProjeto. Leia agents.md, crie snapshot, monitore o container e pare apenas por falha comprovada.

Use $metagpt-pilot para analisar o log do container metagpt-abc e decidir se devo aguardar, trocar de modelo ou recuperar a workspace.
```

## Antes de iniciar

1. Ler `agents.md` ou `AGENTS.md` e verificar se o produto, stack e criterios de aceite estao definidos.
2. Criar uma copia imutavel da especificacao fora da workspace montada e um snapshot recuperavel do projeto.
3. Validar Docker, imagem, launcher, modelo, `max_token` e contexto. Nunca exibir a chave de API.
4. Injetar o conteudo da especificacao no prompt; nao presumir que o MetaGPT lera arquivos montados.
5. Rodar primeiro planejamento ou uma fase limitada. Evitar "implemente o MVP inteiro" quando o modelo usa saida JSON estruturada.
6. Aplicar o perfil a uma copia da configuracao ou ao launcher apenas para a rodada atual; nao alterar a chave e nao reutilizar um perfil de exploracao para JSON ou codigo.
7. Em importadores de planilha, validar uma amostra real pela cadeia completa: estrutura do arquivo -> contadores do lote -> entidades normalizadas -> endpoint agregado -> tela. Um lote com zero linhas deve ter estado explicito e nao ser tratado como sucesso de negocio.
8. Em sessoes paralelas, confirmar que o nome do container, o diretorio montado e o arquivo `runtime/config2.yaml` nao pertencem a outra sessao. A chave deve ser lida de variavel de ambiente exclusiva da sessao e nunca ser escrita em Git, manifest ou log.

Leia `references/failure-playbook.md` antes de escolher modelo ou tratar uma falha. Leia `references/experience-log.md` apenas para aprender com pilotos anteriores; mantenha-o curto.
Leia `references/execution-profiles.md` antes de alterar `config2.yaml`, `n_round`, revisao ou reparo de JSON.
Leia `references/model-routing.md` antes de iniciar uma rodada com selecao automatica.

## Selecao automatica de modelo

1. Tratar um modelo explicito como sobrescrita; somente usar selecao automatica quando o launcher receber `-Model Auto` ou quando nenhum modelo tiver sido indicado.
2. Como MetaGPT usa um unico modelo por container, selecionar por rodada/fase, nunca fingir troca por papel dentro de uma equipe ja iniciada. Para especializar Product Manager, Architect, Engineer ou QA, dividir o trabalho em rodadas pequenas.
3. Derivar a rota por fase, papel, tarefa e dificuldade: `Planning`, `Architecture`, `Implementation`, `Review` ou `Fast`.
4. Executar `scripts/select-metagpt-model.ps1` contra o proxy configurado. Consultar catalogo e fazer no maximo dois probes curtos, sequenciais, sem streaming.
5. Registrar no manifesto rota, modelo, fallbacks, status e latencia dos probes; nunca registrar chave, header ou prompt completo.
6. Em 429, timeout ou 5xx, parar a rodada improdutiva, preservar a workspace e selecionar o proximo fallback com o modelo falho excluido. Em 400/401/403/404/410, marcar a rota como indisponivel/incompativel ate novo health check.
7. Nao usar o catalogo como prova de saude: um modelo listado pode falhar em rota, quota ou compatibilidade. Nao testar todos os modelos antes de cada fase.
8. Registrar fatos em `experience-log.md`. Alterar a matriz somente apos tres rodadas comparaveis aprovadas em testes.

## Execucao e monitoramento

1. Iniciar em segundo plano com nome deterministico de container.
2. Registrar modelo, prompt resumido, diretorio montado, snapshot e horario.
3. Monitorar `docker logs --tail` e a criacao de arquivos, nao apenas o status do container.
4. Considerar progresso somente quando houver artefato salvo, transicao de papel ou teste executado.
5. Em 429 de provedor, respeitar `Retry-After` e fazer uma tentativa adicional no maximo. Em persistencia, trocar modelo ou aguardar capacidade; nunca trocar chaves para burlar limite.
6. Em `JSONDecodeError`, permitir o reparo automatico. Encerrar quando tres reparos falharem, quando o mesmo papel repetir sem novo artefato, ou quando o modelo entrar em repeticao textual.
7. Tratar erros Mermaid de Chromium como nao bloqueantes se os `.mmd` foram preservados.
8. Se duas sessoes compartilham conta, modelo ou provedor, limitar a uma rodada pesada por vez. Em `429` ou `ResourceExhausted`, pausar novas rodadas pesadas no provedor afetado.

## Recuperacao e continuidade

1. Parar o container improdutivo sem apagar a workspace montada.
2. Coletar ultimo papel/acao, erro, modelo, arquivos produzidos e estado de Git.
3. Arquivar artefatos genericos ou incoerentes; nao sobrescrever nem apagar evidencias.
4. Comparar entregas com a especificacao original antes de uma nova rodada.
5. Se a etapa de codigo exigir JSON monolitico e falhar em mais de um modelo, usar MetaGPT apenas para requisitos/arquitetura/revisao e implementar em fases pequenas com testes locais.
6. Ao concluir ou parar, produzir motivo explicito: `COMPLETED`, `UPSTREAM_RATE_LIMIT`, `STRUCTURED_OUTPUT_FAILURE`, `DAILY_QUOTA_EXHAUSTED` ou `PROJECT_DECISION_REQUIRED`.

## Modo autonomo controlado

Quando solicitado, usar `agents.md` como especificacao autoritativa e conduzir o projeto em fases sem pedir confirmacao entre tarefas reversiveis. Criar e manter estado curto, validar cada fase e aplicar o playbook para recuperacao. Parar apenas por decisao material ausente, ausencia de solucao tecnica segura, bloqueio persistente do provedor, falha estruturada repetida ou guarda de orcamento.

Planejar e executar, nesta ordem: banco de dados, autenticacao, permissoes, pipeline de vendas, historico de atividades, API, frontend, workflows e agentes de IA. Para componente nao aplicavel, registrar `NOT_APPLICABLE` e a justificativa; nao antecipar uma camada sem decisao material registrada. Consultar `references/autonomous-project-workflow.md` para criterios de aceite por capacidade.

Aplicar `references/universal-invocation.md` como contrato: projeto pequeno pode ser entregue ponta a ponta; projeto medio ou grande deve ser dividido em fases. Ao fim de cada fase, gerar relatorio, atualizar estado e continuar automaticamente para a proxima fase. O checkpoint nao exige novo comando do usuario.

Definir antes da primeira chamada um orcamento observavel. Ao atingir 95%, salvar estado e parar antes da proxima chamada com `BUDGET_GUARD_REACHED`. Nao estimar como exato um limite que o provedor nao expoe; para franquias gratuitas, usar teto local conservador e tratar a resposta do provedor como autoridade final.

## Uso de tokens e chaves

- Preferir escopo de uma fase por execucao; prompts menores reduzem erro estrutural e repeticao.
- Separar memoria duravel (requisitos, decisoes, estado e criterios de aceite) de contexto de trabalho. Nunca comprimir contratos, especificacoes autoritativas, erros ou codigo necessario para a decisao.
- Usar `max_token` abaixo do teto combinado de entrada e saida anunciado pelo endpoint.
- Usar `GET /api/v1/key` para monitoramento local de credito quando necessario, sem registrar segredo.
- Usar fallback entre modelos e backoff. Contas ou chaves adicionais nao aumentam o rate limit global da OpenRouter.
- Chaves por projeto podem separar orcamento e auditoria, mas nao devem ser alternadas para burlar quota, RPM ou bloqueio de provedor.
- Nunca colocar chave de gerenciamento no MetaGPT. Usar chaves de gerenciamento somente para administracao e rotacao de seguranca.

## Aprendizado continuo

Depois de cada piloto, executar `scripts/record-experience.ps1` com um fato comprovado, sem prompts completos, chaves, dados pessoais ou logs extensos. Se a experiencia mudar uma decisao geral, atualizar `references/failure-playbook.md`; caso contrario, registrar somente uma linha no log. Manter no maximo 30 entradas e consolidar duplicatas.

## Validacao final

1. Confirmar que nao existem containers ativos sem motivo.
2. Validar arquivos, testes e estado do Git.
3. Informar artefatos, modelo, requisicoes desperdicadas evitadas, falhas e proxima acao.
