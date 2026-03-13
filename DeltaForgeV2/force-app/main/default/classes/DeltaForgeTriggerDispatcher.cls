public with sharing class DeltaForgeTriggerDispatcher {
    public static void run(String objectApiName) {
        DeltaForgeOrchestrator.ExecutionDecision decision = evaluateCurrentPhase(objectApiName);
        if (decision == null) {
            return;
        }

        if (decision.spilloverRecommended && !decision.observeOnly) {
            System.debug(
                LoggingLevel.WARN,
                'DELTAFORGE_SPILLOVER_RECOMMENDED phase=' + decision.phaseName + ' pressure=' + decision.pressure
            );
            return;
        }

        // Observe-only phase: business rule execution will be wired in a follow-up slice.
        System.debug(
            LoggingLevel.DEBUG,
            'DELTAFORGE_CONTINUE_SYNC phase=' + decision.phaseName + ' pressure=' + decision.pressure
        );
    }

    @TestVisible
    private static DeltaForgeOrchestrator.ExecutionDecision evaluateCurrentPhase(String objectApiName) {
        return DeltaForgeOrchestrator.evaluateCurrentTransaction(resolvePhaseName(objectApiName));
    }

    @TestVisible
    private static String resolvePhaseName(String objectApiName) {
        String timing = Trigger.isBefore ? 'Before' : 'After';
        String operation = 'Unknown';

        if (Trigger.isInsert) {
            operation = 'Insert';
        } else if (Trigger.isUpdate) {
            operation = 'Update';
        } else if (Trigger.isDelete) {
            operation = 'Delete';
        } else if (Trigger.isUndelete) {
            operation = 'Undelete';
        }

        return objectApiName + ':' + timing + operation;
    }
}
