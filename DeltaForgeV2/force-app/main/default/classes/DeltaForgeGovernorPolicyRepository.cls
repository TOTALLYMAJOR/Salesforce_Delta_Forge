public virtual class DeltaForgeGovernorPolicyRepository {
    public virtual DeltaForgeGovernorPolicy getActivePolicy() {
        List<DeltaForge__GovernorPolicy__mdt> policies = [
            SELECT
                CpuThresholdPct__c,
                SoqlThresholdPct__c,
                DmlThresholdPct__c,
                HeapThresholdPct__c,
                CalloutThresholdPct__c,
                QuantumMaxRules__c,
                QuantumMaxRows__c,
                RollupWindowDefault__c,
                SpilloverChannel__c,
                SpilloverPriority__c,
                ObserveOnly__c,
                SpilloverEnabled__c
            FROM DeltaForge__GovernorPolicy__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];

        if (policies.isEmpty()) {
            return DeltaForgeGovernorPolicy.defaults();
        }

        return DeltaForgeGovernorPolicy.fromMetadata(policies[0]);
    }
}
