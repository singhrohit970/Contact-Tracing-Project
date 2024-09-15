public with sharing class CTDataCleanupSchedule implements Schedulable {
  //sec min hr day month weekday
  public static final String CRON = '0 0 2 * * ?';
  public void execute(SchedulableContext sc) {
    CTPeopleTracingDataCleanupBatch peopleTracingBatch = new CTPeopleTracingDataCleanupBatch();
    Database.executeBatch(peopleTracingBatch, 2000);

    CTLocationTracingDataCleanupBatch locationTracingBatch = new CTLocationTracingDataCleanupBatch();
    Database.executeBatch(locationTracingBatch, 2000);
  }
}
