Atividade 2: Análise de Performance e Otimização de Consulta

1. Análise do Plano de Execução Inicial
A consulta envolvia múltiplas junções e filtro fixo (SalespersonPersonID = 20).

O plano inicial (pelos dados de STATISTICS IO) indicava:

Scan count 2 em InvoiceLines — leitura repetida, indicando possível nested loop ou ausência de índice ideal.

Leitura lógica em Invoices, Customers, People — sem leitura física, mas ainda sem uso de índices ideais.

161 leituras LOB em InvoiceLines

2. Identificação do Gargalo
O ponto mais custoso provavelmente foi a junção com InvoiceLines, dado o Scan count 2 e o número elevado de linhas (22.784).

A tabela Invoices foi lida com logical reads = 22, mas com potencial de otimização pela ausência de índice filtrado ou covering.

Ausência de índices com INCLUDE causava lookups adicionais.

3. Proposta de Otimização

Índice 1: Invoices

CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_Salesperson_Customer] 
ON [Sales].[Invoices] ([SalespersonPersonID], [CustomerID])
INCLUDE ([InvoiceID], [InvoiceDate]);

Cobre a condição do WHERE, a junção com Customers e evita lookup trazendo InvoiceID e InvoiceDate

Índice 2: InvoiceLines

CREATE NONCLUSTERED INDEX [IX_Sales_InvoiceLines_Covering] 
ON [Sales].[InvoiceLines] ([InvoiceID])
INCLUDE ([Quantity], [UnitPrice], [StockItemID]);

Cobre o JOIN com Invoices e já inclui as colunas selecionadas, evitando lookups.

Índice 3: People

CREATE NONCLUSTERED INDEX [IX_Application_People_PersonID] 
ON [Application].[People] ([PersonID])
INCLUDE ([FullName]);

Cobre a junção e evita buscar FullName em heap ou estrutura separada.

Índice 4: Customers

CREATE NONCLUSTERED INDEX [IX_Sales_Customers_CustomerID] 
ON [Sales].[Customers] ([CustomerID])
INCLUDE ([CustomerName]);

Cobre a junção e elimina lookup desnecessário para CustomerName

Índices Filtrados

CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_Optimized] 
ON [Sales].[Invoices] ([SalespersonPersonID])
INCLUDE ([InvoiceID], [InvoiceDate], [CustomerID])
WHERE [SalespersonPersonID] = 20;

Justificativa: para consultas com SalespersonPersonID = 20, um índice filtrado torna a busca ainda mais rápida.

Útil se esse filtro for muito recorrente.

4. Validação

Nenhuma leitura física, tudo em cache.

Scan count = 1 ou 0, o que mostra uso de índices seek-based, muito mais eficientes.

Redução de logical reads e CPU:

Antes: CPU time = 32 ms, elapsed time = 34 ms

Depois: CPU time = 21 ms, elapsed time = 26 ms

A quantidade de linhas retornadas (22.784) é constante, mas o custo de processamento foi reduzido.