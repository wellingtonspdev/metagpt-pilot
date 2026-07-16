# Protocolo de Pesquisa e Gerenciamento de Modelos

## Gatilhos

Antes de uma rodada, consultar o catalogo do proxy. Acionar pesquisa antes de promover um modelo quando ocorrer um dos eventos:

- modelo presente no catalogo e ausente de `model-registry.json`;
- `research_stale: true` (padrao: mais de 14 dias sem revisao);
- tres falhas comparaveis, 429 persistente ou degradacao de tool/JSON em um modelo habilitado;
- necessidade nova de modalidade, contexto, ferramenta ou politica de dados.

Nao pesquisar todos os modelos a cada rodada. Um catalogo pode mudar varias vezes ao dia; a pesquisa deve ser orientada por diferenca, risco e necessidade da fase.

## Fontes e hierarquia

1. Fonte oficial do provedor/desenvolvedor: contexto, modalidades, tool calling, licenca, politica de dados e limites.
2. Benchmark independente: Artificial Analysis ou leaderboard que exponha metodo e versao.
3. Benchmark oficial do dominio: por exemplo, SWE-bench Verified para software engineering. Comparar apenas resultados sob mesmo harness/versao.
4. Dados do OpenRouter: providers, uptime, latencia, throughput e erro de tool call. Tratar como telemetria operacional, nao prova de qualidade.
5. Numeros do fabricante: registrar como `vendor_benchmark`; nao usar isoladamente para promover um modelo.

Registrar URLs, data, versao do modelo, metodo, contexto, saida, modalidade, observacoes de privacidade e qualquer limitacao de comparabilidade.

## Comparacao por cenario

Avaliar somente os modelos compativeis com a fase:

| Cenario | Evidencia prioritaria | Criterio de promocao |
| --- | --- | --- |
| PRD e planejamento | Instrucao, raciocinio, contexto, latencia | Smoke MetaGPT concluido e artefato coerente. |
| Arquitetura e bug dificil | Raciocinio, contexto, recuperacao de informacao | Decisao revisada e criterios tecnicos satisfeitos. |
| Implementacao | Coding, terminal, tools, testes de repositorio | Build/testes passam em tres rodadas comparaveis. |
| Revisao | Coding, raciocinio, precisao de diagnostico | Encontra problema real ou confirma ausencia com evidencia. |
| Subtarefa rapida | Latencia, JSON/edicao localizada | Artefato valido sem reparo recorrente. |

## Ciclo de promocao

1. Descobrir: catalogo e health check curto.
2. Pesquisar: fontes conforme hierarquia.
3. Registrar: adicionar modelo inicialmente com `enabled: false` e evidencia/riscos no registry.
4. Experimentar: tres fases comparaveis, com modelo, latencia, chamadas, testes, falhas JSON/tools e intervencao humana.
5. Promover: definir `enabled: true` e prioridade somente se a evidencia operacional superar a alternativa atual.
6. Rebaixar: desabilitar em falha sistematica ou risco de dados inaceitavel; preservar historico no relatorio/experience log.

## Regras de seguranca e custo

- Nunca registrar chave, header, prompt sensivel ou resposta privada em registry, manifesto ou relatorio.
- Usar no maximo dois probes curtos por selecao e nao testar o catalogo inteiro antes de cada fase.
- Tratar 429/5xx como indisponibilidade temporaria; nao trocar chaves para burlar quota.
- Tratar 400/401/403/404/410 como configuracao, retirada ou incompatibilidade ate nova validacao.
