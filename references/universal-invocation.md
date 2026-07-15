# Invocacao Universal

## Objetivo

Depois da instalacao unica do MetaGPT, Docker e da skill, o usuario deve fornecer somente a skill e, quando necessario, o caminho do projeto. A IA piloto assume o restante do ciclo operacional.

## Comandos de uso

Quando o terminal ou agente ja estiver na raiz do projeto:

```text
Use $metagpt-pilot
```

Quando o projeto estiver em outra pasta:

```text
Use $metagpt-pilot para iniciar o projeto em D:\Projetos\MeuProjeto
```

Em runtimes que nao usam a sintaxe `$skill`:

```text
Use a skill metagpt-pilot para iniciar o projeto em D:\Projetos\MeuProjeto.
```

Nao exigir que o usuario informe modelo, perfil, prompt de fase, nome de container, local de logs ou proxima etapa. Esses detalhes sao responsabilidade da IA piloto.

## Descoberta automatica

1. Usar o caminho informado; sem caminho, usar o diretorio de trabalho atual.
2. Procurar `agents.md` e depois `AGENTS.md` na raiz. A primeira especificacao encontrada e a fonte autoritativa.
3. Carregar `.planning/`, `README.md`, documentos de decisoes e estado ja existentes apenas como contexto complementar. Eles nao podem contradizer a especificacao autoritativa sem uma decisao registrada.
4. Se nao houver especificacao, parar com `PROJECT_DECISION_REQUIRED` e informar os caminhos procurados. Nao inventar requisitos.
5. Criar snapshot da especificacao, estado inicial, diretorio de logs e identificador de sessao sem expor a chave.

## Classificacao do escopo

| Classe | Criterio | Estrategia |
| --- | --- | --- |
| Pequeno | Uma capacidade limitada, poucos modulos e sem dependencia material entre banco, identidade, frontend, workflows ou agentes. | Planejar e implementar ponta a ponta em rodada limitada, com testes e validacao final. |
| Medio | Mais de uma capacidade ou integracao, mas com fronteiras claras e baixo risco de saida estruturada extensa. | Criar plano curto e executar em duas ou mais fases. |
| Grande | Banco, autenticacao, permissoes, dominio de vendas, API, frontend, automacoes, agentes ou multiplas integracoes. | Criar roadmap completo e executar uma fase por rodada, respeitando a ordem obrigatoria de desenvolvimento. |

Na duvida, classificar como grande. O objetivo e evitar respostas JSON monoliticas, loops e perda de contexto.

## Fluxo sem intervencao do usuario

1. Ler a especificacao e mapear o repositorio.
2. Criar roadmap e fases somente quando o escopo for medio ou grande.
3. Executar a fase atual com o perfil apropriado.
4. Monitorar container, artefatos, testes, quota e progresso real.
5. Recuperar falhas reversiveis pelo playbook.
6. Gerar relatorio de fase e atualizar estado.
7. Iniciar automaticamente a proxima fase, sem pedir um novo comando, enquanto houver escopo aprovado e orcamento seguro.
8. Ao concluir, executar validacao integrada e gerar relatorio final.

O checkpoint no fim de fase e uma parada de controle e relatorio, nao uma espera por comando humano. A IA piloto continua para a fase seguinte automaticamente, exceto pelos codigos de parada definidos no fluxo autonomo.

## Relatorio obrigatorio por fase

Salvar `docs/metagpt/phase-reports/fase-XX.md` ou equivalente no diretorio de sessao. Cada relatorio deve ter:

```text
Fase: <numero e nome>
Status: COMPLETED | BLOCKED | NOT_APPLICABLE
Escopo executado: <itens>
Artefatos alterados: <caminhos>
Validacao: <testes, build, endpoints ou evidencias>
Falhas e recuperacoes: <fatos>
Consumo observado: <orcamento/telemetria disponivel>
Proxima fase: <numero, objetivo e criterio de aceite>
Pendente: <somente bloqueios reais>
```

## Ordem para projetos grandes

Aplicar a ordem definida em `autonomous-project-workflow.md`: banco de dados, autenticacao, permissoes, pipeline de vendas, historico de atividades, API, frontend, workflows e agentes de IA. Registrar itens ausentes como `NOT_APPLICABLE`; nao pular ou antecipar silenciosamente.

## Pre-condicoes unicas

O usuario precisa apenas ter concluido uma vez: instalar MetaGPT e Docker, instalar a skill e disponibilizar uma chave autorizada na variavel de ambiente da sessao. Depois disso, a invocacao universal nao pede parametros operacionais adicionais.
