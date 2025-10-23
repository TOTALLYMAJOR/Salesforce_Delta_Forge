# Salesforce_Delta_Forge
<img width="1024" height="1024" alt="DeltaForge Architecture" src="https://github.com/user-attachments/assets/3bdc385e-2ccd-4516-9b15-f2eff8a1a564" />

Architecture Overview
A deterministic delta engine, an idempotent outbox, and a verifiable telemetry ledger run inside one orchestration layer.
Key components (novel where noted): 1. Delta Orchestrator (Apex Trigger Framework): Single entry per SObject, after/before handlers consolidated. Orders rules by declared dependencies with a cost‑based optimizer. 2. Change Mask + Delta Cache: Computes changedFields and old→new maps. Prevents no‑op DML. Shared across all rules in a transaction. 3. Derivation Rule Engine (Metadata DSL): Declarative rules stored in custom metadata. Evaluated in bulk, CRUD/FLS checked. Deterministic order via DAG. 4. Lookup Rollup Service: Incremental rollups using delta sets and windowed SOQL, not full‑table scans. 5. Outbox (Custom Object + Platform Events): Post‑commit publisher with idempotency keys and exponential backoff workers. 6. Verifiable Telemetry Ledger (Novel): Tamper‑evident append‑only Big Object with Merkle chaining of event batches and per‑record lineage hashes. 7. Rule Simulator: Offline runner with seed data and diff reports.
Data Model (custom)
    • DeltaForge__Rule__mdt - fields: ApiName, Version, Active, SourceObject, When (before/after), DependsOn (Set), ChangeFilter (expr), DerivationExpr (expr), TargetFields (Set), CostHint (Number), WriteSemantics (Overwrite|Min|Max|Append).
    • DeltaForge__Outbox__c - Key (External Id), Topic, Payload (Encrypted Text), Headers (JSON), State (Queued|Sent|Failed|Dead), Attempts, NextAttemptAt, Hash (SHA‑256), RecordRef (Polymorphic), RuleRef (Lookup), CorrelationId.
    • DeltaForge__OutboxWorker__c - configuration: concurrency, backoff curve, endpoints, OAuth named credentials, idempotency window.
    • Big Object DeltaForge__Ledger__b (Novel): LedgerId (PK prefix + date), Seq, EventType (Change|Derivation|Send), RecordId, Rule, DeltaJson, PrevBatchHash, BatchHash, CorrelationId, Clock (logical), CpuMs, RowsScanned.
    • DeltaForge__Dependency__mdt - adjacency list for rule DAG.
Exactly‑Once Design
    • Semantic Idempotency Key: hash(Topic + canonical(payload) + version(rule) + targetSystem) makes retries non‑duplicative.
    • Outbox State Machine: transitions only after commit via afterCommit queueable. Worker enforces single‑flight per key.
    • Receiver Contract: include Idempotency-Key header; optional probe endpoint to check prior receipt.
Cost‑Based Rule Ordering
    • Compute per‑rule cost from historical CpuMs and RowsScanned in Ledger. Use greedy topological order to minimize governor pressure while honoring dependencies. Per‑object kill switch.
Observability
    • Every derivation and send writes a ledger record whose BatchHash chains to the previous batch. Weekly anchor hash exported to external store for integrity proofs.
    • Correlation via CorrelationId across logs, outbox, and ledger. Admin console shows lineage per record.
Failure and Replay
    • Dead‑letter queue: Outbox.State=Dead after backoff ceiling. Replay UI re‑queues with the same idempotency key.
    • Partial failures do not roll back DML. Only post‑commit work retries.
PlantUML: Component Diagram
@startuml
skinparam componentStyle rectangle
package "DeltaForge" {
  [Trigger Entry] --> [Delta Orchestrator]
  [Delta Orchestrator] --> [Change Mask + Cache]
  [Delta Orchestrator] --> [Rule Engine]
  [Rule Engine] --> [Lookup Rollup Service]
  [Delta Orchestrator] --> [Unit of Work]
  [Unit of Work] --> [DML]
  [Delta Orchestrator] --> [Outbox Publisher]
  [Outbox Publisher] --> [Outbox (CObj)]
  [Outbox (CObj)] --> [Platform Event]
  [Workers (Queueable/Batch)] --> [HTTP Endpoint]
  [All Components] --> [Ledger (Big Object)]
}
@enduml
PlantUML: Write and Send Sequence
@startuml
actor User
participant "Trigger Entry" as T
participant "Orchestrator" as O
participant "Rule Engine" as R
participant "UoW" as U
participant "Outbox" as X
participant "AfterCommit Worker" as W
participant "HTTP Target" as H

User -> T: DML (insert/update)
T -> O: before/after context
O -> R: compute deltas, evaluate rules
R -> U: stage change set
U -> U: apply change-only DML
O -> X: enqueue send(Key, Payload)
O -> O: write Ledger events
... commit ...
W -> X: fetch queued by due time
W -> H: POST with Idempotency-Key
H --> W: 200/409 based on prior receipt
W -> X: mark Sent or Failed
@enduml
Security
    • Evaluate rules with CRUD/FLS checks before reads and writes. Payloads encrypted at rest via Shield‑compatible fields if enabled. Secrets live in Named Credentials.




Key upgrades:
Switched to Named Credential + External Credential, Queueable Apex with Finalizer, and Platform Events for async delivery. Caching and circuit breaker added.
Tightened security: WITH SECURITY_ENFORCED, no secrets in code, PE unsubscribe on disconnect.
Clear trade-offs section and full landscape + sequence diagrams.
Added typed DTOs and a Result<T> wrapper.
Provided logged observability via Smart_Log__c and dashboards guidance.
Included a Fusiaolia spreadsheet CSV template for dev task tracking.
Delivered commented LWC and Apex illustrating retries, backoff, cache, breaker, and KB fallback.
