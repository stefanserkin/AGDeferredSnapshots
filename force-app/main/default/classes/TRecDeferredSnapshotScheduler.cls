public with sharing class TRecDeferredSnapshotScheduler implements Schedulable {
    
    public static String schedule = '0 15 5 ? * *'; // Every day at 5:15am

    public static final String JOB_NAME = TRecDeferredSnapshotBatch.BATCH_NAME;

    public static String run() {
        TRecDeferredSnapshotScheduler sched = new TRecDeferredSnapshotScheduler();
        return System.schedule(JOB_NAME, schedule, sched);
    }

    public void execute(SchedulableContext context) {
        TRecDeferredSnapshotBatch batch = new TRecDeferredSnapshotBatch();
        Id batchId = Database.executeBatch(batch, 200);
    }

}