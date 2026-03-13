public with sharing class DeltaForgeGovernorBudgetManager {
    public enum PressureLevel {
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    public class GovernorSnapshot {
        public Integer cpuUsedMs;
        public Integer cpuLimitMs;
        public Integer soqlUsed;
        public Integer soqlLimit;
        public Integer dmlRowsUsed;
        public Integer dmlRowsLimit;
        public Integer heapUsedKb;
        public Integer heapLimitKb;
        public Integer calloutsUsed;
        public Integer calloutsLimit;
        public String pressure;
        public Boolean observeOnly;
        public Boolean spilloverEnabled;
    }

    public class BudgetDecision {
        public GovernorSnapshot snapshot;
        public PressureLevel pressureLevel;
        public Boolean observeOnly;
        public Boolean spilloverRecommended;
    }

    private final DeltaForgeGovernorPolicyRepository policyRepository;

    public DeltaForgeGovernorBudgetManager() {
        this(new DeltaForgeGovernorPolicyRepository());
    }

    public DeltaForgeGovernorBudgetManager(DeltaForgeGovernorPolicyRepository policyRepository) {
        this.policyRepository = policyRepository;
    }

    public BudgetDecision evaluate() {
        DeltaForgeGovernorPolicy policy = policyRepository.getActivePolicy();
        GovernorSnapshot snapshot = buildSnapshot(policy);
        PressureLevel pressureLevel = calculatePressure(snapshot, policy);
        snapshot.pressure = String.valueOf(pressureLevel);

        BudgetDecision decision = new BudgetDecision();
        decision.snapshot = snapshot;
        decision.pressureLevel = pressureLevel;
        decision.observeOnly = policy.observeOnly;
        decision.spilloverRecommended = shouldSpillover(pressureLevel, policy);
        return decision;
    }

    public Boolean shouldSpillover(PressureLevel pressureLevel, DeltaForgeGovernorPolicy policy) {
        if (policy == null || pressureLevel == null) {
            return false;
        }
        if (policy.observeOnly || !policy.spilloverEnabled) {
            return false;
        }
        return pressureLevel == PressureLevel.HIGH || pressureLevel == PressureLevel.CRITICAL;
    }

    private static GovernorSnapshot buildSnapshot(DeltaForgeGovernorPolicy policy) {
        GovernorSnapshot snapshot = new GovernorSnapshot();
        snapshot.cpuUsedMs = Limits.getCpuTime();
        snapshot.cpuLimitMs = Limits.getLimitCpuTime();
        snapshot.soqlUsed = Limits.getQueries();
        snapshot.soqlLimit = Limits.getLimitQueries();
        snapshot.dmlRowsUsed = Limits.getDmlRows();
        snapshot.dmlRowsLimit = Limits.getLimitDmlRows();
        snapshot.heapUsedKb = Limits.getHeapSize() / 1024;
        snapshot.heapLimitKb = Limits.getLimitHeapSize() / 1024;
        snapshot.calloutsUsed = Limits.getCallouts();
        snapshot.calloutsLimit = Limits.getLimitCallouts();
        snapshot.observeOnly = policy != null && policy.observeOnly;
        snapshot.spilloverEnabled = policy != null && policy.spilloverEnabled;
        return snapshot;
    }

    private static PressureLevel calculatePressure(GovernorSnapshot snapshot, DeltaForgeGovernorPolicy policy) {
        Integer cpuPct = percentUsed(snapshot.cpuUsedMs, snapshot.cpuLimitMs);
        Integer soqlPct = percentUsed(snapshot.soqlUsed, snapshot.soqlLimit);
        Integer dmlPct = percentUsed(snapshot.dmlRowsUsed, snapshot.dmlRowsLimit);
        Integer heapPct = percentUsed(snapshot.heapUsedKb, snapshot.heapLimitKb);
        Integer calloutPct = percentUsed(snapshot.calloutsUsed, snapshot.calloutsLimit);

        if (
            cpuPct >= criticalThreshold(policy.cpuThresholdPct) ||
            soqlPct >= criticalThreshold(policy.soqlThresholdPct) ||
            dmlPct >= criticalThreshold(policy.dmlThresholdPct) ||
            heapPct >= criticalThreshold(policy.heapThresholdPct) ||
            calloutPct >= criticalThreshold(policy.calloutThresholdPct)
        ) {
            return PressureLevel.CRITICAL;
        }

        if (
            cpuPct >= safeThreshold(policy.cpuThresholdPct) ||
            soqlPct >= safeThreshold(policy.soqlThresholdPct) ||
            dmlPct >= safeThreshold(policy.dmlThresholdPct) ||
            heapPct >= safeThreshold(policy.heapThresholdPct) ||
            calloutPct >= safeThreshold(policy.calloutThresholdPct)
        ) {
            return PressureLevel.HIGH;
        }

        Integer maxPct = Math.max(
            Math.max(cpuPct, soqlPct),
            Math.max(Math.max(dmlPct, heapPct), calloutPct)
        );
        if (maxPct >= 60) {
            return PressureLevel.MEDIUM;
        }
        return PressureLevel.LOW;
    }

    private static Integer safeThreshold(Integer thresholdPct) {
        if (thresholdPct == null) {
            return 85;
        }
        return Math.max(0, Math.min(100, thresholdPct));
    }

    private static Integer criticalThreshold(Integer thresholdPct) {
        return Math.min(100, safeThreshold(thresholdPct) + 10);
    }

    private static Integer percentUsed(Integer used, Integer limitValue) {
        if (used == null || limitValue == null || limitValue <= 0) {
            return 0;
        }
        return (used * 100) / limitValue;
    }
}
