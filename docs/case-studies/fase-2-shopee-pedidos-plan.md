# Fase 2: Pedidos e Importacao Shopee

## Objetivo

Implementar a importacao local de planilhas Shopee e a operacao de pedidos centralizados sobre o nucleo existente de produtos, SKUs e estoque.

## Escopo aprovado

1. Ler arquivos XLSX e CSV da Shopee, preservando cada linha bruta e relatando erros por linha.
2. Criar lotes de importacao e detectar duplicatas por marketplace, conta, pedido externo, SKU externo e variacao.
3. Persistir pedidos, itens e dados financeiros normalizados sem descartar o JSON original.
4. Expor historico de importacoes, lista paginada de pedidos e detalhe completo do pedido.
5. Listar SKUs externos sem vinculo e permitir o vinculo manual ao SKU interno.
6. Baixar estoque uma unica vez por item vinculado, registrando a movimentacao de venda e mantendo idempotencia.

## Interfaces previstas

| Operacao | Endpoint |
| --- | --- |
| Importar planilha Shopee | `POST /api/imports/shopee` |
| Consultar lotes | `GET /api/imports` |
| Consultar lote | `GET /api/imports/{id}` |
| Listar pedidos com filtros | `GET /api/orders` |
| Consultar pedido | `GET /api/orders/{id}` |
| Processar estoque do pedido | `POST /api/orders/{id}/process-stock` |
| Listar SKUs nao vinculados | `GET /api/skus/unlinked` |
| Criar vinculo externo-interno | `POST /api/marketplace-sku-links` |

## Regras de dados

- A importacao deve ser transacional por lote.
- `raw_import_rows` guarda a linha original; pedidos, itens e financeiro mantem `raw_data`.
- O importador normaliza cabecalhos, datas e valores antes de persistir.
- Cada item vinculado gera no maximo uma movimentacao `SALE`; itens sem vinculo ficam com status pendente.
- A amostra real de planilha Shopee deve validar o mapeamento de colunas antes da implementacao final.

## Arquivos de implementacao previstos

1. `backend/app/importers/base.py`
2. `backend/app/importers/shopee.py`
3. `backend/app/api/imports.py`
4. `backend/app/api/orders.py`
5. `backend/app/api/skus.py`
6. `backend/app/services/order.py`
7. `backend/app/services/stock.py`
8. `backend/app/schemas/order.py`
9. `backend/app/schemas/import_batch.py`
10. `backend/tests/test_shopee_importer.py`
11. `backend/tests/test_order_stock_processing.py`
12. `frontend/src/pages/ImportSales.tsx`

As telas `Orders.tsx` e `UnlinkedSkus.tsx` devem entrar em uma tarefa de frontend subsequente para manter cada unidade de entrega pequena.

## Criterios de aceite

1. Um XLSX ou CSV valido cria um lote com totais de linhas, importadas, duplicadas e com erro.
2. Uma linha invalida e registrada com numero da linha, mensagem e dado bruto, sem invalidar as demais linhas validas.
3. Reimportar o mesmo arquivo nao duplica pedidos ou itens.
4. Pedidos podem ser filtrados por conta, periodo, status e situacao de estoque.
5. O detalhe do pedido mostra itens, financeiro, movimentacoes e dados brutos.
6. Itens sem vinculo aparecem na consulta de pendencias.
7. Criar um vinculo permite processar o item pendente posteriormente.
8. Processar o mesmo pedido duas vezes nao cria nova movimentacao nem reduz estoque novamente.
9. Uma falha na baixa deixa estado auditavel e nao corrompe o saldo.
10. Os testes cobrem importacao, duplicidade, SKU nao vinculado e idempotencia de estoque.

## Riscos e premissas

- O formato exato da exportacao Shopee precisa de uma amostra real; os nomes e a quantidade de colunas nao devem ser codificados como regra inflexivel.
- Processamento assincrono e backup automatico para arquivos grandes permanecem decisao de implementacao posterior do MVP.
- Este plano foi consolidado a partir do experimento P1 do MetaGPT, interrompido antes da etapa de tarefas porque o agente excedeu o limite solicitado de arquivos.
