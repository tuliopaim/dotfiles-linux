# Portfolio data

These notes describe the deployed schema as of 2026-10-17. Run the helper's `schema` command for current columns and relationships. The source checkout is `~/dev/portfolio`; `CONTEXT.md` is its canonical domain vocabulary. Application code and the live schema are authoritative when these notes differ.

## Units and dates

- Monetary decimals are major units: BRL `Amount`, budgets and `TotalBrl` are reais; `AmountUsd` is dollars. Never divide by 100. API monetary decimals also use major units.
- SQLite stores C# decimals as TEXT. Preserve decimal strings and use Python `Decimal` for exact sums. Lexical ordering is wrong for numeric values. `CAST(column AS REAL)` is suitable for approximate comparisons, not exact accounting.
- PTAX and `ExchangeRate` are BRL per USD. Cotação is per asset unit. `LatestRatePercent = 7.34` means 7.34%.
- `PortfolioDate` is a São Paulo calendar date. `ImportedAtUtc` is recording time, which can be a later day. Dates use `YYYY-MM-DD`, Finance `Month` uses the first day, `YYYY-MM-01`.
- Finance spending categories and portfolio Categorias are separate concepts.

## Investments and history

- `Assets` is the current Registry. Key columns include `Investment`, `Category`, `Note`, `Quantity`, `PriceSource`, nullable `LatestPrice`, `LatestPriceCurrency`, `LatestPriceAtUtc`, `LastFetchedAtUtc`, `LatestRatePercent` and `MaturityDate`. `Investment` is unique with NOCASE collation. A zero Quantidade is valid.
- `DailySnapshots` has `Id`, unique `PortfolioDate`, `TotalBrl`, `AssetCount`, `ImportedAtUtc`.
- `AssetSnapshots` belongs to `DailySnapshots` through `DailySnapshotId`. It records `Investment`, `Category`, `NoteValue`, `QuantityValue`, `QuantitySource`, `QuoteValue`, `QuoteDisplayCurrency`, `TotalBrl`. One Investimento per Snapshot. Quantity and quote fields can be null.
- `CategorySnapshots` has `DailySnapshotId`, `Category`, `TotalBrl`. Join to `DailySnapshots` for dates.
- `ptax_usd_brl_quotations` has unique `QuotationDate`, `CotacaoCompra`, `CotacaoVenda`, `FetchedAtUtc`, `CreatedAtUtc`, `UpdatedAtUtc`. Compra can be null.
- Snapshot assets have no foreign key to Registry assets. Join by `Investment` only when needed, retaining the historical Categoria and values.

Portfolio Categorias are `Ações BR`, `Cripto`, `ETF - $`, `ETF - R$`, `FII`, `Renda Fixa`. `PriceSource` is `B3`, `LSE`, `Crypto` or `Tesouro`; Registry currency is `BRL` or `USD`. These are strings, not numeric enum values.

Snapshots are authoritative historical observations. Never rebuild past values from today's Registry. The current-day Snapshot can be replaced when updated. USD valuation uses the latest PTAX `CotacaoVenda` on or before the Portfolio date and rounds each asset to two decimals.

Older sheet-era `QuoteDisplayCurrency` can incorrectly say BRL for a USD quote. `TotalBrl` already contains the historical BRL valuation. Applying PTAX again double-converts it. The application's historical comparison uses `TotalBrl / QuantityValue` as an effective BRL quote when quantity is available. Use the currency-attribution endpoint for the tested calculation.

A Period opens at the Snapshot on `from`, or the latest before it, and measures later Snapshots through `to`. A single-day Period has a value but nothing measured. A change in TotalBrl includes money flows and is not itself an investment return.

Nota controls the relative share of its Categoria's next Aporte. Nota zero excludes that asset from suggestions while retaining it in total portfolio value. Aporte is buy-only; only positive Deficits receive it. Category targets are basis points in the preview request, with 2500 meaning 25%. There is no persisted target table in SQLite. The Aporte draft is saved in that browser's localStorage under `portfolio.aporte-session`; a database query cannot recover those settings. Ask for the intended targets when unavailable.

## Personal Finance

- `FinanceEntries`: `Id`, `Date`, `Month`, `Description`, `Category`, `OriginalCategory`, `CategorySource`, `CategoryConfidence`, `Kind`, `Amount`, `AmountUsd`, `ExchangeRate`, `Card`, `Cardholder`, `Installment`, `Installments`, `ImportKey`, nullable `StatementId`.
- `FinanceStatements`: `Id`, `FileName`, `DueDate`, `ImportedAtUtc`. Entries link through `StatementId`.
- `FinanceMerchantNames`: unique raw `Description` plus display `Name`, shared across months. There is no `Name` column in FinanceEntries. Join by Description for aliases.
- `FinanceBudgets`: unique `(Month, Category)` plus `Amount`. These are monthly spending limits, unrelated to portfolio targets.
- Operational tables such as `__EFMigrationsHistory` are not ledger data.

Imported purchases use purchase `Date` and statement due-date `Month`. An earlier purchase billed in October belongs to `Month = '2026-10-01'`. Manual entries use their transaction-date month.

`Kind` values and signs:

| Kind | Sign of Amount | Included in spending |
| --- | --- | --- |
| `purchase` | Nonnegative | Yes |
| `refund` | Negative | Yes, reduces spending |
| `expense` | Positive | Yes |
| `income` | Positive | No |
| `payment` | Negative | No, bill payment would double-count spending |

Spending is purchases + signed refunds + manual expenses. Balance is income minus spending. Refunds remain separate signed rows. API credit/payment totals display positive magnitudes.

Amount is the billed installment, not the whole purchase. Future installments are projections. The service deduplicates installment series using transaction identity and the latest known statement up to the selected month. Summing future projections from every historical row double-counts commitments; use `/api/finance/month`.

Imports deduplicate through a unique ImportKey, which includes statement due date and occurrence count. Identical transactions in one file can be separate purchases. Do not remove duplicates using DISTINCT on description/date/amount.

`CategorySource` is `bank`, `learned`, `model` or `user`; user choices survive automatic organization. Categories currently include Alimentação, Mercado, Transporte, Viagens, Moradia, Saúde, Pets, Compras, Assinaturas, IA, Lazer, Serviços, Tarifas and Outros. Query actual values rather than relying on this list.

## Existing application calculations

On homelab or another tailnet machine, the deployed base URL is `http://portfolio`. From a machine without that DNS/network access, run curl through `ssh homelab`. The base route is `/api`.

| Request | Use |
| --- | --- |
| GET `/management/assets` | Current Registry valuation and quote health |
| GET `/dashboard/summary` | Latest Snapshot overview |
| GET `/dashboard/composition?date=YYYY-MM-DD` | Snapshot on or before a date |
| GET `/dashboard/history?from=YYYY-MM-DD&to=YYYY-MM-DD` | Stored totals with application Period rules |
| GET `/dashboard/performance?from=...&to=...` | Return and flow decomposition; optional `category` or `asset`, one at a time |
| GET `/dashboard/performance/assets` or `/dashboard/performance/categories` | Per-asset or per-Categoria performance; accepts `from`/`to` |
| GET `/dashboard/currency-attribution?from=...&to=...` | Market and PTAX effects |
| GET `/dashboard/categories/history` or `/dashboard/assets/history` | Breakdown histories; accepts `from`/`to` |
| GET `/assets/{URL-encoded-investment}?days=90` | Investimento detail/history |
| GET `/finance/month?month=YYYY-MM` | Spending totals, budgets, merchant aliases and future installments |
| GET `/ptax/quotations?from=YYYY-MM-DD&to=YYYY-MM-DD` | Historical PTAX |
| GET `/management/snapshots` or `/management/snapshots/{id}` | Inspect stored Snapshots |

```sh
curl --fail --silent --show-error --get 'http://portfolio/api/finance/month' \
  --data-urlencode 'month=2026-10'
curl --fail --silent --show-error --get 'http://portfolio/api/dashboard/performance' \
  --data-urlencode 'from=2026-01-01' --data-urlencode 'to=2026-10-17'
```

POST `/api/rebalance/preview` is a read-only Aporte calculation. It requires the current `snapshotDate`, `contributionBrl`, and `categoryTargets` with `category`/`targetBps`; `selectedCategories` is optional. Fetch summary/composition first for the actual date and category names. Targets must come from the user or actual saved settings. Do not invent them. The body shape is:

```json
{
  "snapshotDate": "YYYY-MM-DD",
  "contributionBrl": 1000,
  "categoryTargets": [{"category": "<actual Categoria>", "targetBps": 10000}]
}
```

That illustrates the shape only. Supply one target for every Categoria in the current Snapshot, with targetBps totaling exactly 10000. Send a prepared JSON file with `curl --fail --silent --show-error -H 'Content-Type: application/json' --data-binary @/path/to/preview.json 'http://portfolio/api/rebalance/preview'`. This endpoint can reject a stale Snapshot or invalid targets. Other POST/PATCH/PUT/DELETE routes are outside this skill's read-only workflow.

## SQL examples

Inspect live schema before using these. Bind `:date`, `:month`, `:investment` through `query --params`.

```sql
-- Registry facts, preserving stored decimal strings.
SELECT Investment, Category, Note, Quantity, LatestPrice, LatestPriceCurrency
FROM Assets ORDER BY Investment;

-- Actual holdings on the latest Snapshot on/before a given date.
SELECT d.PortfolioDate, a.Investment, a.Category, a.QuantityValue, a.TotalBrl
FROM DailySnapshots d
JOIN AssetSnapshots a ON a.DailySnapshotId = d.Id
WHERE d.Id = (
  SELECT Id FROM DailySnapshots WHERE PortfolioDate <= :date
  ORDER BY PortfolioDate DESC LIMIT 1
)
ORDER BY a.Category, a.Investment;

-- Spending rows for an accounting month, including signed refunds.
SELECT e.Id, e.Date, e.Month, e.Description, n.Name, e.Category, e.Kind, e.Amount
FROM FinanceEntries e
LEFT JOIN FinanceMerchantNames n ON n.Description = e.Description
WHERE e.Month = :month AND e.Kind IN ('purchase', 'refund', 'expense')
ORDER BY e.Date DESC, e.Id DESC;
```

Execute each statement separately. Use explicit ordering and pagination for large datasets and check `truncated`. Statements in separate commands use separate production snapshots; use one query for facts that must be observed together.
