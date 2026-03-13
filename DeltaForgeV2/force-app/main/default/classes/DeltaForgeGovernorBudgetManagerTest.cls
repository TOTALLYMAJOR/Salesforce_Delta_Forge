@IsTest
private class DeltaForgeGovernorBudgetManagerTest {
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
    static void evaluateObserveOnlyPolicyDoesNotSpill() {
        DeltaForgeGovernorPolicy policy = DeltaForgeGovernorPolicy.defaults();
        policy.cpuThresholdPct = 0;
        policy.observeOnly = true;
        policy.spilloverEnabled = true;

        DeltaForgeGovernorBudgetManager manager = new DeltaForgeGovernorBudgetManager(
            new StubPolicyRepository(policy)
        );

        DeltaForgeGovernorBudgetManager.BudgetDecision decision = manager.evaluate();
        System.assertEquals(true, decision.observeOnly, 'Observe-only mode must stay enabled.');
        System.assertEquals(false, decision.spilloverRecommended, 'Observe-only mode cannot spill work.');
        System.assert(
            new Set<String>{ 'HIGH', 'CRITICAL' }.contains(decision.snapshot.pressure),
            'Pressure should be elevated when thresholds are set to zero.'
        );
    }

    @IsTest
    static void evaluateSpilloverRecommendationWhenPressureHigh() {
        DeltaForgeGovernorPolicy policy = DeltaForgeGovernorPolicy.defaults();
        policy.cpuThresholdPct = 0;
        policy.observeOnly = false;
        policy.spilloverEnabled = true;

        DeltaForgeGovernorBudgetManager manager = new DeltaForgeGovernorBudgetManager(
            new StubPolicyRepository(policy)
        );

        DeltaForgeGovernorBudgetManager.BudgetDecision decision = manager.evaluate();
        System.assertEquals(false, decision.observeOnly, 'Observe-only mode should be disabled in this test.');
        System.assertEquals(true, decision.spilloverRecommended, 'High pressure should recommend spillover.');
    }

    @IsTest
    static void evaluateHighThresholdPolicyKeepsSyncPath() {
        DeltaForgeGovernorPolicy policy = DeltaForgeGovernorPolicy.defaults();
        policy.cpuThresholdPct = 100;
        policy.soqlThresholdPct = 100;
        policy.dmlThresholdPct = 100;
        policy.heapThresholdPct = 100;
        policy.calloutThresholdPct = 100;
        policy.observeOnly = false;
        policy.spilloverEnabled = true;

        DeltaForgeGovernorBudgetManager manager = new DeltaForgeGovernorBudgetManager(
            new StubPolicyRepository(policy)
        );

        DeltaForgeGovernorBudgetManager.BudgetDecision decision = manager.evaluate();
        System.assertEquals(false, decision.spilloverRecommended, 'Spillover should not be recommended here.');
        System.assertNotEquals(null, decision.snapshot.pressure, 'Pressure must always be populated.');
    }
}
