public class DeltaForgeGovernorPolicy {
    public Integer cpuThresholdPct { get; set; }
    public Integer soqlThresholdPct { get; set; }
    public Integer dmlThresholdPct { get; set; }
    public Integer heapThresholdPct { get; set; }
    public Integer calloutThresholdPct { get; set; }
    public Integer quantumMaxRules { get; set; }
    public Integer quantumMaxRows { get; set; }
    public Integer rollupWindowDefault { get; set; }
    public String spilloverChannel { get; set; }
    public String spilloverPriority { get; set; }
    public Boolean observeOnly { get; set; }
    public Boolean spilloverEnabled { get; set; }

    public static DeltaForgeGovernorPolicy defaults() {
        DeltaForgeGovernorPolicy policy = new DeltaForgeGovernorPolicy();
        policy.cpuThresholdPct = 85;
        policy.soqlThresholdPct = 80;
        policy.dmlThresholdPct = 80;
        policy.heapThresholdPct = 80;
        policy.calloutThresholdPct = 80;
        policy.quantumMaxRules = 25;
        policy.quantumMaxRows = 200;
        policy.rollupWindowDefault = 200;
        policy.spilloverChannel = 'Queueable';
        policy.spilloverPriority = 'Low';
        policy.observeOnly = true;
        policy.spilloverEnabled = true;
        return policy;
    }

    public static DeltaForgeGovernorPolicy fromMetadata(DeltaForge__GovernorPolicy__mdt policyMdt) {
        DeltaForgeGovernorPolicy policy = defaults();
        if (policyMdt == null) {
            return policy;
        }

        policy.cpuThresholdPct = toInteger(policyMdt.CpuThresholdPct__c, policy.cpuThresholdPct);
        policy.soqlThresholdPct = toInteger(policyMdt.SoqlThresholdPct__c, policy.soqlThresholdPct);
        policy.dmlThresholdPct = toInteger(policyMdt.DmlThresholdPct__c, policy.dmlThresholdPct);
        policy.heapThresholdPct = toInteger(policyMdt.HeapThresholdPct__c, policy.heapThresholdPct);
        policy.calloutThresholdPct = toInteger(policyMdt.CalloutThresholdPct__c, policy.calloutThresholdPct);
        policy.quantumMaxRules = toInteger(policyMdt.QuantumMaxRules__c, policy.quantumMaxRules);
        policy.quantumMaxRows = toInteger(policyMdt.QuantumMaxRows__c, policy.quantumMaxRows);
        policy.rollupWindowDefault = toInteger(policyMdt.RollupWindowDefault__c, policy.rollupWindowDefault);
        policy.spilloverChannel = String.isBlank(policyMdt.SpilloverChannel__c)
            ? policy.spilloverChannel
            : policyMdt.SpilloverChannel__c;
        policy.spilloverPriority = String.isBlank(policyMdt.SpilloverPriority__c)
            ? policy.spilloverPriority
            : policyMdt.SpilloverPriority__c;
        policy.observeOnly = policyMdt.ObserveOnly__c == null ? policy.observeOnly : policyMdt.ObserveOnly__c;
        policy.spilloverEnabled = policyMdt.SpilloverEnabled__c == null
            ? policy.spilloverEnabled
            : policyMdt.SpilloverEnabled__c;
        return policy;
    }

    private static Integer toInteger(Decimal value, Integer fallbackValue) {
        if (value == null) {
            return fallbackValue;
        }
        return value.intValue();
    }
}
