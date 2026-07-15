# Sessoes MetaGPT em Paralelo

## Objetivo

Executar projetos independentes ao mesmo tempo sem compartilhar workspace, configuracao local, nome de container, logs ou snapshots.

## Isolamento obrigatorio

Cada sessao deve ter identificadores exclusivos:

| Recurso | Sessao 1 | Sessao 2 |
| --- | --- | --- |
| Projeto | `D:\Projetos\projeto-a` | `D:\Projetos\projeto-b` |
| Diretorio | `D:\MetaGPT\runs\session-1` | `D:\MetaGPT\runs\session-2` |
| Container | `metagpt-session-1-projeto-a` | `metagpt-session-2-projeto-b` |
| Config runtime | `session-1\runtime\config2.yaml` | `session-2\runtime\config2.yaml` |
| Variavel de chave | `METAGPT_SESSION_1_API_KEY` | `METAGPT_SESSION_2_API_KEY` |

Nao montar o mesmo projeto em dois containers que possam escrever nele. Nao usar a mesma configuracao gravavel em duas sessoes.

## Chaves de API

Uma chave diferente por projeto e tecnicamente suportada quando cada chave e autorizada para seu projeto, conta ou workspace. O uso aceitavel e segregacao de custo, auditoria, revogacao e limite de credito por projeto.

Nao rotacionar chaves, criar contas ou automatizar troca de chaves para burlar RPM, limite diario, indisponibilidade ou regras do provedor. Em OpenRouter, chaves adicionais nao aumentam a capacidade global da conta.

Nunca registrar o valor de uma chave em comando, log, manifest, Git ou relatorio. O launcher recebe apenas o nome da variavel de ambiente.

## Politica de concorrencia

1. Definir modelo, perfil, teto de chamadas e artefato de sucesso por sessao.
2. Se as sessoes usam a mesma conta, mesmo modelo gratuito ou mesmo provedor, iniciar apenas uma rodada pesada por vez.
3. Priorizar planejamento leve de um projeto em paralelo com validacao/testes locais de outro.
4. Em `429` ou `ResourceExhausted`, pausar a sessao afetada, respeitar `Retry-After` e nao iniciar nova rodada pesada no mesmo provedor.
5. Monitorar CPU, memoria, Docker e espaco em disco. Encerrar sessoes sem progresso comprovado.

## Preparar a sessao 2 no Windows

1. Copie os tres arquivos em `templates/` para `D:\MetaGPT\runs\session-2\`.
2. Mantenha `runtime/` e `logs/` fora do Git.
3. No PowerShell da segunda sessao, defina a chave apenas para aquele processo:

```powershell
$env:METAGPT_SESSION_2_API_KEY = "<chave-da-sessao-2>"
```

4. Inicie uma fase limitada:

```powershell
Set-Location D:\MetaGPT\runs\session-2
.\run-metagpt-session.ps1 `
  -ProjectRoot "D:\Projetos\projeto-b" `
  -Requirement "Produza somente o plano da fase atual." `
  -ProjectName "projeto-b" `
  -Profile P1 `
  -Rounds 3
```

5. Em outro terminal, acompanhe o container:

```powershell
.\monitor-metagpt-session.ps1 -ContainerName "metagpt-session-2-projeto-b"
```

6. Ao terminar, valide arquivos e testes antes de remover o container e `runtime/config2.yaml`.

## Estado de validacao

O isolamento por diretorio, configuracao e container foi preparado e revisado estaticamente. A execucao simultanea de dois projetos com cargas reais, a recuperacao de cada container e a medicao de interferencia de quota ainda devem ser testadas antes de declarar esse modo estavel.
