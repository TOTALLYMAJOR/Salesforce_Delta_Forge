public with sharing class DeltaForgeOrchestrator {
    public class ExecutionDecision {
        public String phaseName;
        public String action;
        public String pressure;
        public Boolean observeOnly;
        public Boolean spilloverRecommended;
    }

    private final DeltaForgeGovernorBudgetManager budgetManager;

    public DeltaForgeOrchestrator() {
        this(new DeltaForgeGovernorBudgetManager());
    }

    public DeltaForgeOrchestrator(DeltaForgeGovernorBudgetManager budgetManager) {
        this.budgetManager = budgetManager;
    }

    public ExecutionDecision evaluatePhase(String phaseName) {
        DeltaForgeGovernorBudgetManager.BudgetDecision budgetDecision = budgetManager.evaluate();
        DeltaForgeObservability.logGovernorSnapshot(phaseName, budgetDecision.snapshot);

        ExecutionDecision decision = new ExecutionDecision();
        decision.phaseName = phaseName;
        decision.observeOnly = budgetDecision.observeOnly;
        decision.spilloverRecommended = budgetDecision.spilloverRecommended;
        decision.pressure = budgetDecision.snapshot.pressure;
        decision.action = budgetDecision.spilloverRecommended ? 'SPILL_TO_ASYNC' : 'CONTINUE_SYNC';
        return decision;
    }

    public static ExecutionDecision evaluateCurrentTransaction(String phaseName) {
        return new DeltaForgeOrchestrator().evaluatePhase(phaseName);
    }
}
