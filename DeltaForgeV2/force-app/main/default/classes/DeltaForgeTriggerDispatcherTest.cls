@IsTest
private class DeltaForgeTriggerDispatcherTest {
    @IsTest
    static void accountTriggerExecutesDispatcherAcrossLifecycle() {
        Account accountRecord = new Account(Name = 'DeltaForge Trigger Test');

        Test.startTest();
        insert accountRecord;
        accountRecord.Name = 'DeltaForge Trigger Test Updated';
        update accountRecord;
        delete accountRecord;
        Test.stopTest();

        Integer allRowsCount = [SELECT COUNT() FROM Account WHERE Id = :accountRecord.Id ALL ROWS];
        System.assertEquals(1, allRowsCount, 'Account should have been inserted and soft-deleted.');
    }

    @IsTest
    static void orchestratorReturnsDecisionOutsideTriggerContext() {
        DeltaForgeOrchestrator.ExecutionDecision decision = DeltaForgeOrchestrator.evaluateCurrentTransaction(
            'UnitTest:ManualCheck'
        );
        System.assertNotEquals(null, decision, 'Decision should be returned.');
        System.assertNotEquals(null, decision.action, 'Decision should include an action.');
        System.assertEquals('CONTINUE_SYNC', decision.action, 'Default policy should remain observe-only.');
    }
}
