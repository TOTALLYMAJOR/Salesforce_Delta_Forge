# DeltaForge Governor-Limit Technical Specification

## 1. Goal
Provide a governor-limit–aware execution model for DeltaForge that remains deterministic, bulkified, and idempotent while preventing CPU, SOQL, DML, heap, and callout limit violations.

## 2. Scope
- Applies to Trigger Entry, Delta Orchestrator, Rule Engine, Rollups, Outbox, and Ledger.
- Covers synchronous and asynchronous execution paths.
- Adds runtime limit budgeting, adaptive batching, and spillover mechanisms.

## 3. Non-Goals
- Replacing the existing data model (we extend it with additional metadata).
- Removing existing determinism guarantees.
- Changing the external integration contract.

## 4. Key Principles
1. **Adaptive Budgeting**: Track remaining limits and allocate budgets per subsystem.
2. **Lazy Materialization**: Avoid building large in-memory maps unless needed.
3. **Quantized Work Units**: Process work in safe “quanta” sized by live telemetry.
4. **Deterministic Degradation**: Rule execution is prioritized and deterministic under pressure.
5. **Idempotent Spillover**: Deferred work uses the same semantic idempotency key.

## 5. Governor Budgets

### 5.1 Budget Manager (New Component)
**Name:** `GovernorBudgetManager`

**Responsibilities:**
- Compute remaining CPU, SOQL, DML, heap, callout, and PE publish budgets.
- Allocate per-phase budgets (Rules, Rollups, Outbox, Ledger).
- Expose thresholds for degradation or spillover.

**Sample Allocation Defaults (per transaction):**
- Rule Evaluation: 45%
- Rollups: 20%
- Outbox: 15%
- Ledger: 10%
- Safety Reserve: 10%

### 5.2 Budget Consumption Signals
| Signal | Source | Usage |
|---|---|---|
| `Limits.getCpuTime()` | Apex | CPU burn monitoring |
| `Limits.getQueries()` | Apex | SOQL usage monitoring |
| `Limits.getDmlRows()` | Apex | DML usage monitoring |
| `Limits.getHeapSize()` | Apex | Heap usage monitoring |
| `Limits.getCallouts()` | Apex | Callout usage monitoring |

## 6. Quantized Execution Pattern

### 6.1 Quantum Definition
A quantum is a **bounded unit of work** that includes a subset of rules and records, sized based on:
- Current governor usage
- Cost hints from Ledger
- Expected DML amplification

### 6.2 Quantum Planner
**Name:** `QuantumPlanner`

**Inputs:**
- Rule DAG + costs
- Record counts per SObject
- Historical CPU/SOQL cost per rule

**Outputs:**
- Ordered list of quanta (Rule groups + record subsets)
- Per-quantum cost budget

### 6.3 Execution Flow
1. Compute remaining budgets.
2. Plan quanta within budgets.
3. Execute quanta in priority order.
4. Spill remaining quanta to async if thresholds breached.

## 7. Rule Engine Enhancements

### 7.1 Rule Sharding
- Split DAG by topological layers.
- Execute high-priority layers synchronously, defer lower layers.

### 7.2 Expression Compilation Cache
- Pre-compile DSL expressions at deployment time.
- Cache in `PlatformCache` or static map keyed by RuleId + Version.

### 7.3 Change Mask Streaming
- Use iterator-based evaluation to avoid full object materialization.
- Compute field deltas on demand.

## 8. Rollup Service Enhancements

### 8.1 Windowed Rollups with Adaptive Window Size
- Window size starts from `RollupWindowDefault` and shrinks if CPU/SOQL budget tight.
- Persist rollup progress in `DeltaForge__RollupCursor__c`.

### 8.2 Rollup Spillover
- Large parent sets are split into `PlatformEvent` batches.
- Each PE includes cursor + idempotency key.

## 9. Outbox Enhancements

### 9.1 Batch Enqueue
- Insert Outbox rows in bulk per quantum.
- Enforce max rows per transaction based on `DmlBudget`.

### 9.2 Adaptive Worker Concurrency
- Concurrency scaled based on CPU and callout limits in async context.

## 10. Ledger Enhancements

### 10.1 Ledger Compaction
- Store per-quantum summary in Big Object, detailed entries only when debug flag on.

### 10.2 Merkle Hash Streaming
- Compute hash in streaming manner to avoid full memory retention.

## 11. New Metadata

### 11.1 `DeltaForge__GovernorPolicy__mdt`
| Field | Purpose |
|---|---|
| `CpuThresholdPct` | Degrade when exceeded |
| `SoqlThresholdPct` | Degrade when exceeded |
| `DmlThresholdPct` | Degrade when exceeded |
| `HeapThresholdPct` | Degrade when exceeded |
| `QuantumMaxRules` | Hard cap per quantum |
| `QuantumMaxRows` | Hard cap per quantum |
| `RollupWindowDefault` | Base window size |
| `SpilloverChannel` | Queueable / PE |
| `SpilloverPriority` | High/Medium/Low |

## 12. Error Handling & Degradation Rules
- If CPU > threshold: stop evaluation of low-priority rules, spill remaining.
- If SOQL > threshold: suspend rollups and enqueue async rollup.
- If Heap > threshold: switch to streaming mode or spill.
- Always maintain deterministic ordering within a quantum.

## 13. Observability
- Add Ledger events with `GovernorSnapshot` JSON blob.
- Add Smart_Log__c entries for budget exhaustion events.

## 14. Success Criteria
- 0 governor-limit exceptions under load tests (10k records).
- Rule engine throughput maintains ≥ 80% of baseline for average load.
- Spillover tasks complete within configured SLA.
