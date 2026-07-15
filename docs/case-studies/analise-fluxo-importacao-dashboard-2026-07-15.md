# Analise do Fluxo: Importacao, Banco e Dashboard

Data: 2026-07-15

## Evidencia observada

No banco local ativo, o lote da planilha `Order.completed.20250201_20250303.xlsx` possuia inicialmente os contadores `total_rows=0`, `imported_rows=0`, `duplicate_rows=0` e `error_rows=0`. O endpoint `/api/orders` retornava uma lista vazia. A planilha possui a aba `orders`, um unico cabecalho (`ID do pedido`) e nenhuma linha de venda.

Portanto, o numero de pedidos igual a zero era o resultado correto para aquele arquivo. Nao era falha de renderizacao do frontend nem perda de dados pelo importador.

## Fluxo implementado

1. O frontend envia CSV/XLSX para `POST /api/imports/shopee`.
2. O importador cria `import_batches` para auditoria do arquivo.
3. Para cada linha valida, preserva `raw_import_rows` e cria ou relaciona `orders`, `order_items` e `order_financials`.
4. Os pedidos normalizados podem ser consultados por `/api/orders`, vinculados a SKUs internos e processados para baixa idempotente de estoque.
5. `GET /api/dashboard/overview` calcula os indicadores diretamente no SQLite, sem depender da pagina de pedidos nem de dados brutos.
6. O frontend consome esse endpoint para pedidos, itens, faturamento e alertas de estoque.

## Dados brutos e normalizados

`raw_import_rows` preserva cada linha de dados recebida para auditoria e investigacao de falhas. `orders`, `order_items` e `order_financials` sao a representacao normalizada usada por consultas, dashboard, vinculo de SKU e estoque. Dados brutos nao devem ser usados diretamente como fonte de KPI.

## Correcao entregue

- Arquivos sem linhas de dados agora recebem status `NO_DATA_ROWS`, em vez de parecerem uma importacao de negocio concluida.
- Lotes legados inequivocamente vazios sao reclassificados na inicializacao do backend.
- O dashboard agora consulta `/api/dashboard/overview`, que agrega `orders`, `order_items`, `order_financials`, `stock_balances` e `import_batches` no backend.
- O frontend mostra um aviso contextual quando existem importacoes sem dados.

## Testes executados

- Importacao com linha valida alimenta pedidos, itens e indicadores agregados.
- Importacao com cabecalho somente retorna `NO_DATA_ROWS` e incrementa `no_data_imports`.
- Suite backend: 7 testes aprovados.
- Build React/Vite aprovado.
- Endpoint agregado validado pelo proxy Vite com a resposta `no_data_imports: 1` para a planilha real vazia.

## Limite atual

Ainda e necessaria uma exportacao Shopee com pedidos reais para validar aliases de cabecalhos, datas, valores, status, duplicidade e o resultado de negocio completo.

## Validacao MetaGPT

A rodada P4 do MetaGPT recebeu as evidencias e retornou a mesma causa e recomendacao de agregacao no backend. A rodada foi encerrada quando o provedor retornou `ResourceExhausted (160/32)`, sem repeticao. Isso confirma a politica da skill de usar o modelo para decisao curta e interromper diante de limite do provedor.
