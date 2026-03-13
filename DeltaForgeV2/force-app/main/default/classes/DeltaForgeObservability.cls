public with sharing class DeltaForgeObservability {
    public static void logGovernorSnapshot(
        String phaseName,
        DeltaForgeGovernorBudgetManager.GovernorSnapshot snapshot
    ) {
        if (snapshot == null) {
            return;
        }

        Map<String, Object> payload = new Map<String, Object>{
            'phase' => phaseName,
            'cpuUsedMs' => snapshot.cpuUsedMs,
            'cpuLimitMs' => snapshot.cpuLimitMs,
            'soqlUsed' => snapshot.soqlUsed,
            'soqlLimit' => snapshot.soqlLimit,
            'dmlRowsUsed' => snapshot.dmlRowsUsed,
            'dmlRowsLimit' => snapshot.dmlRowsLimit,
            'heapUsedKb' => snapshot.heapUsedKb,
            'heapLimitKb' => snapshot.heapLimitKb,
            'calloutsUsed' => snapshot.calloutsUsed,
            'calloutsLimit' => snapshot.calloutsLimit,
            'pressure' => snapshot.pressure,
            'observeOnly' => snapshot.observeOnly,
            'spilloverEnabled' => snapshot.spilloverEnabled
        };

        System.debug(LoggingLevel.INFO, 'DELTAFORGE_GOVERNOR_SNAPSHOT ' + JSON.serialize(payload));
    }
}
