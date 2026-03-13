# DeltaForge Governor-Limit Phase 1 Decisions

## Date
- March 11, 2026

## Scope
- Initial scaffolding for governor-aware orchestration.
- Policy metadata, runtime budget evaluation, and observe-only orchestrator integration.

## Decisions
1. Default spillover channel is `Queueable`.
2. Default rollout mode is `Observe Only = true`.
3. Spillover feature flag ships enabled, but is gated by observe-only mode.
4. A single `Default` policy record is created for initial deployment.
5. Rollup continuation state is stored in `DeltaForge__RollupCursor__c`.

## Guardrails
1. No synchronous behavior changes while observe-only is true.
2. Governor snapshots are logged for each evaluated phase.
3. Pressure-based spillover is only allowed when observe-only is false.

## Follow-up
1. Add org-profile policy variants (scratch/sandbox/production).
2. Add custom logging sink (Smart_Log__c or platform event) after schema is finalized.
3. Wire orchestrator evaluation into trigger entry points.
