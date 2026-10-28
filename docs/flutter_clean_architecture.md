# TradeX Flutter Clean Architecture Migration

This migration is intentionally incremental. Every feature must remain
shippable after each commit.

## Dependency rule

```text
presentation -> domain <- data
                     ^
                 composition
```

- `domain` contains entities, repository contracts and use cases. It cannot
  import Flutter, API clients, storage implementations, data or presentation.
- `data` contains remote/local data sources, transport models, mappers and
  repository implementations.
- `presentation` consumes domain use cases and entities. It cannot instantiate
  API clients or import feature data implementations.
- A feature composition root wires its concrete dependencies at the app edge.
- Existing API routes, navigation, visual behavior and persistence contracts
  remain unchanged unless a separate product change explicitly requires it.

## Migration order

1. Baseline analyzer and full tests.
2. Shared use-case contract and architecture dependency tests.
3. Support (migrated).
4. Copy Trading.
5. Affiliate.
6. Learn.
7. Trade Ideas.
8. Crypto Market.
9. Trade Journal.
10. Catalog and secure workflows.
11. Home dashboard.
12. Authentication and remaining profile workflows.

For every feature: add characterization tests first, migrate one dependency
boundary at a time, run targeted tests, run `flutter analyze`, then run the
full suite before committing.
