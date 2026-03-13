@IsTest
private class DeltaForgeOrchestratorTest {
    private class StubPolicyRepository extends DeltaForgeGovernorPolicyRepository {
        private final DeltaForgeGovernorPolicy policy;

        StubPolicyRepository(DeltaForgeGovernorPolicy policy) {
            this.policy = policy;
        }

        public override DeltaForgeGovernorPolicy getActivePolicy() {
            return policy;
        }
    }

    @IsTest
    static void evaluatePhaseReturnsContinueSyncForObserveOnly() {
        DeltaForgeGovernorPolicy policy = DeltaForgeGovernorPolicy.defaults();
        policy.cpuThresholdPct = 0;
        policy.observeOnly = true;
        policy.spilloverEnabled = true;

        DeltaForgeGovernorBudgetManager manager = new DeltaForgeGovernorBudgetManager(
            new StubPolicyRepository(policy)
        );
        DeltaForgeOrchestrator orchestrator = new DeltaForgeOrchestrator(manager);

        DeltaForgeOrchestrator.ExecutionDecision decision = orchestrator.evaluatePhase('RuleEvaluation');
        System.assertEquals('CONTINUE_SYNC', decision.action, 'Observe-only mode should keep sync execution.');
        System.assertEquals(true, decision.observeOnly, 'Observe-only mode should be visible to callers.');
    }

    @IsTest
    static void evaluatePhaseReturnsSpillActionWhenAllowed() {
        DeltaForgeGovernorPolicy policy = DeltaForgeGovernorPolicy.defaults();
        policy.cpuThresholdPct = 0;
        policy.observeOnly = false;
        policy.spilloverEnabled = true;

        DeltaForgeGovernorBudgetManager manager = new DeltaForgeGovernorBudgetManager(
            new StubPolicyRepository(policy)
        );
        DeltaForgeOrchestrator orchestrator = new DeltaForgeOrchestrator(manager);

        DeltaForgeOrchestrator.ExecutionDecision decision = orchestrator.evaluatePhase('RuleEvaluation');
        System.assertEquals('SPILL_TO_ASYNC', decision.action, 'High pressure should recommend spillover.');
        System.assertEquals(true, decision.spilloverRecommended, 'Spillover flag should be enabled.');
    }
}
