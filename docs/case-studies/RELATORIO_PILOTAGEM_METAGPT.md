# Relatorio de Pilotagem do MetaGPT

Data: 2026-07-14
Projeto: Marketplace Inteligente
Diretorio: `D:\Markertplace_inteligente`

## 1. Objetivo

Usar o MetaGPT oficial como uma empresa de software multiagente para desenvolver o projeto a partir de `agents.md`, consumindo modelos gratuitos da OpenRouter de forma controlada e preservando todos os artefatos produzidos.

## 2. Ambiente efetivamente utilizado

| Item | Estado |
|---|---|
| MetaGPT | clone limpo do repositorio oficial em `D:\MetaGPT` e imagem `metagpt/metagpt:latest` |
| Execucao | Docker, Windows/PowerShell, container em segundo plano para monitoramento |
| Configuracao | `D:\MetaGPT\.metagpt\config2.yaml`, com segredo mantido fora de commits |
| Orquestrador | `D:\MetaGPT\run-metagpt-gsd.ps1` |
| Metodo de trabalho | `D:\MetaGPT\.metagpt\META_GPT_GSD.md` injetado no prompt sem alterar o codigo-fonte do MetaGPT |
| Especificacao | copia imutavel em `D:\MetaGPT\.metagpt\specifications\marketplace-agents.md` |
| Agentes oficiais observados | Product Manager, Architect, Project Manager, Engineer (com revisao) e QA |

O launcher usou `inc=True`, `code_review=True`, `run_tests=True` e `implement=True`. O container foi iniciado de forma destacada, acompanhado por `docker logs`, e encerrado apenas quando houve evidencia de loop improdutivo.

## 3. Linha do tempo

1. A instalacao anterior foi preservada como backup e o MetaGPT foi reinstalado a partir do repositorio oficial.
2. Foi criado um launcher externo para montar a configuracao e o projeto no container, sem patch no MetaGPT.
3. A primeira abordagem apenas apontava para `agents.md`. O MetaGPT nao leu o arquivo por conta propria e derivou requisitos genericos.
4. O `agents.md` original foi recuperado de backup, salvo no projeto e em uma localizacao externa imutavel.
5. O launcher foi ajustado para injetar integralmente a especificacao no prompt. Isso eliminou a perda de contexto sobre o Marketplace Inteligente.
6. Foi criado snapshot do projeto antes de cada nova execucao e os artefatos genericos incorretos foram preservados em `.metagpt-discarded/`, sem descarte destrutivo.
7. A execucao com North Mini Code gerou PRD, arquitetura e tarefas, mas falhou na etapa de plano detalhado de codigo.
8. A tentativa com Qwen3 Coder encontrou rate limit temporario do provedor Venice, inclusive apos o intervalo informado pelo provedor.
9. A tentativa com Nemotron 3 Ultra gerou documentos de alto nivel, mas retornou JSON invalido no mesmo estagio de plano de codigo.
10. O piloto foi encerrado quando ficou claro que repetir chamadas consumiria quota sem aproximar a implementacao.
11. A implementacao passou para fases menores e verificaveis fora do loop monolitico do MetaGPT. O nucleo FastAPI/SQLite foi iniciado e testado.

## 4. Resultados preservados

Os seguintes artefatos foram gerados e mantidos:

- `agents.md`: especificacao recuperada e validada.
- `docs/requirement.txt`: requisito consolidado.
- `docs/prd/20260714180018.json`: PRD estruturado.
- `docs/system_design/20260714180018.json`: desenho arquitetural.
- `docs/task/20260714180018.json`: tarefas planejadas.
- `resources/*.mmd`: fontes Mermaid dos diagramas.
- `.planning/`: contexto, requisitos, roadmap e estado para continuidade em GSD.
- `backend/`: nucleo inicial de API e testes de estoque.
- `docs/OPENROUTER_KEY_AND_METAGPT_FEASIBILITY.md`: estudo de chaves e capacidade.

Validacao feita no backend: `python -m pytest backend/tests -q` retornou `2 passed`.

## 5. Falhas, diagnostico e tratamento

| Falha | Causa confirmada | Tratamento aplicado | Licao operacional |
|---|---|---|---|
| Requisitos genericos | O MetaGPT nao leu automaticamente `agents.md` montado no projeto | Injecao integral da especificacao no prompt | Nunca depender de leitura implicita de arquivo pelo agente |
| Especificacao desapareceu do projeto | O workspace do MetaGPT reorganizou/inicializou o repositorio | Recuperacao do backup, copia externa imutavel e snapshots | Nunca montar a unica copia de requisitos como unica fonte de verdade |
| `JSONDecodeError` em respostas | Modelos gratuitos emitiram texto ou JSON malformado no protocolo estruturado | Reparos automaticos foram aguardados uma vez; processos foram encerrados ao evidenciar repeticao | Medir progresso por artefatos e logs, nao apenas por processo ativo |
| North Mini Code repetiu plano sem codigo | Contrato `WriteCodePlanAndChange` retornou JSON invalido de dezenas de milhares de caracteres | Container interrompido apos tres reparos invalidos | Nao usar este modelo nesse estagio MetaGPT |
| Qwen3 Coder 429 | Capacidade do provedor Venice esgotada temporariamente | Respeito a `Retry-After`; tentativa posterior; troca de modelo | Tratar 429 de provedor como indisponibilidade, nao como defeito do projeto |
| Nemotron 3 Ultra JSON invalido | Resposta do plano de codigo excedeu/violou a serializacao esperada | Encerramento apos tres reparos; preservacao dos documentos | O fluxo oficial e fragil quando exige uma unica resposta JSON enorme |
| Mermaid nao gerou PNG/PDF/SVG | Chromium nao roda como root sem `--no-sandbox` no container | Mantidos os `.mmd`; falha nao bloqueou produto | Diagramas renderizados sao opcionais; nao gastar quota de LLM para essa falha local |
| Avisos de custo/tokenizer | Modelos OpenRouter nao existem no catalogo interno de custos do MetaGPT | Apenas monitoramento; nao e falha de inferencia | Nao usar o contador interno como fonte de quota real |
| SQLite em memoria nos testes | Cada thread abriu conexao independente no `TestClient` | Fixture corrigido com `StaticPool` | Testes FastAPI+SQLite devem compartilhar conexao de memoria |

## 6. Limitacoes confirmadas do MetaGPT neste cenario

1. O MetaGPT oficial e mais confiavel como gerador de requisitos, arquitetura e decomposicao do que como executor de um MVP amplo em uma unica rodada.
2. O fluxo `WriteCodePlanAndChange` exige um objeto JSON muito grande. Em endpoints gratuitos, esse contrato falhou antes de qualquer arquivo de codigo ser escrito.
3. `n_round` nao transforma uma execucao interrompida em retomada confiavel. A API oficial aceita `recover_path`, mas o estado serializado nao foi encontrado no workspace das execucoes interrompidas.
4. `inc=True` ainda pode reorganizar a workspace. Nao tratar a raiz montada como local imutavel.
5. Fallback de modelo da OpenRouter nao e automaticamente usado pelo MetaGPT somente por existir uma lista no YAML. O cliente precisa suportar o parametro `models` ou a troca deve ser feita pelo piloto.
6. A configuracao de `max_token` deve obedecer ao teto de entrada mais saida do endpoint. Definir a saida no maximo nominal pode resultar em erro 400 antes da chamada.

## 7. Procedimento recomendado para proximas execucoes

### Antes de iniciar

1. Validar Docker, imagem, configuracao e sintaxe do launcher.
2. Nunca imprimir ou registrar a chave da API.
3. Manter a especificacao em um caminho externo imutavel e injetar seu conteudo no prompt.
4. Criar snapshot fora da pasta montada.
5. Iniciar com um escopo pequeno: requisitos/arquitetura, uma fase backend, uma fase frontend ou revisao. Nao pedir MVP inteiro quando a rota usa JSON estruturado fragil.
6. Definir modelo, contexto e saida conforme os limites reais atuais do endpoint.

### Durante a execucao

1. Usar `docker run -d --name ...` e monitorar com `docker logs --tail`.
2. Considerar progresso apenas quando houver arquivo salvo, mudanca de papel ou teste executado.
3. Em 429 de provedor, respeitar `Retry-After` e fazer no maximo uma nova tentativa antes de trocar de modelo.
4. Em `JSONDecodeError`, permitir o reparo automatico; encerrar quando tres reparos falharem ou quando o mesmo estagio repetir sem novo artefato.
5. Tratar falha Mermaid como nao bloqueante, salvo se o objetivo for gerar imagens de diagramas.
6. Ao parar, registrar explicitamente: modelo, papel/acao, ultimo erro, artefatos e proxima acao segura.

### Depois

1. Validar os arquivos contra `agents.md`; nao assumir que um PRD gerado e fiel.
2. Arquivar produtos genericos/invalidos, sem excluir evidencias.
3. Converter os artefatos validos em fases menores de implementacao e testes.
4. Atualizar a skill de pilotagem com fatos novos, sem adicionar logs completos ou segredos.

## 8. Atalhos seguros

```powershell
# Validar sintaxe do launcher
$errors = $null; $tokens = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
  'D:\MetaGPT\run-metagpt-gsd.ps1', [ref]$tokens, [ref]$errors
)
$errors

# Verificar um container em andamento
docker ps -a --filter "name=metagpt" --format '{{.Names}} {{.Status}}'
docker logs --tail 100 <container>

# Parar uma execucao improdutiva preservando a workspace montada
docker stop --timeout 15 <container>
docker rm <container>

# Validar backend atual
Set-Location D:\Markertplace_inteligente
$env:PYTHONPATH = (Resolve-Path backend).Path
python -m pytest backend\tests -q
```

## 9. Gerenciamento de chaves e limites

Nao implementar rotacao de varias chaves ou contas para ampliar quota gratuita. A documentacao da OpenRouter informa que chaves e contas adicionais nao alteram os rate limits porque a capacidade e global. Use uma unica chave de inferencia por ambiente, backoff, `Retry-After`, monitoramento por `GET /api/v1/key` e fallback entre modelos.

Para aumento legitimo de capacidade: adicionar creditos na mesma conta, usar modelo pago ou configurar BYOK de um provedor contratado. Chaves de gerenciamento servem para rotacao de seguranca e administracao, nao para inferencia.

Fontes oficiais:

- https://openrouter.ai/docs/api_reference/limits
- https://openrouter.ai/docs/guides/routing/model-fallbacks
- https://openrouter.ai/docs/guides/overview/auth/management-api-keys

## 10. Decisao de continuidade

Para este projeto, manter MetaGPT como orquestrador de planejamento e revisao quando houver modelo compativel com JSON estruturado. Executar implementacao em fases menores, com testes locais e estado GSD, e nunca repetir a fase monolitica de codigo sob o mesmo modelo apos falha de serializacao comprovada.
