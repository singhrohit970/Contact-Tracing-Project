public with sharing class CTPersonTriggerHandler {
  public static void beforeInsert(List<Person__c> newRecords) {
    //Before insert operation for Person__c Object
    //make sure the health status is green
    //generate unique token for each record
    //System.debug('value of newRecords ' + newRecords);
    //Now we need to set the token of all records
    //As we are inserting multiple records, we can use for loop in our code.
    for (Person__c person : newRecords) {
      //update person status to Green
      person.Health_Status__c = 'Green';
      //generate unique token
      person.Token__c = CTPersonController.getToken(person.Mobile__c);
    }
  }
  //before update operation for Person__c object
  public static void beforeUpdate(List<Person__c> newRecords,Map<Id, Person__c> oldRecordMap) {
    System.debug('value of newRecords :' +newRecords);
    System.debug('value of oldrecord :' +oldRecordMap);
    for (Person__c person : newRecords) {
      //check if the status changed in this transaction
      //also update Status_Update_Date__c

      if (person.Health_Status__c != oldRecordMap.get(person.id).Health_Status__c) {
        person.Status_Update_Date__c = Date.today();
      }
    }
  }

  public static void afterUpdate(
    List<Person__c> newRecords,
    Map<Id, Person__c> oldRecordMap
  ) {
    Set<Id> statusChange = new Set<Id>();
    Set<Id> redStatus = new Set<Id>();

    for (Person__c person : newRecords) {
      if (
        person.Health_Status__c != oldRecordMap.get(person.id).Health_Status__c
      ) {
        statusChange.add(person.Id);
      }
      if (
        person.Health_Status__c == 'Red' &&
        oldRecordMap.get(person.id).Health_Status__c != 'Red'
      ) {
        redStatus.add(person.Id);
      }
    }

    Set<Id> alreadyProcessed = new Set<Id>();
    alreadyProcessed.addAll(redStatus);

    Set<Id> orangeStatus = new Set<Id>();
    Set<Id> yellowStatus = new Set<Id>();

    List<Person__c> personToUpdate = new List<Person__c>();

    //lets add cohabitants
    orangeStatus.addAll(CTPersonController.getCohabitants(redStatus, alreadyProcessed));

    //lets add primarycontacts
    Set<Id> primaryContacts = CTPersonController.getPrimaryContact(redStatus,alreadyProcessed);
    orangeStatus.addAll(primaryContacts);
    //lets add neighnours
    yellowStatus.addAll(CTPersonController.getNeighbours(redStatus, alreadyProcessed));

    //lets add secondaryContacts
    yellowStatus.addAll(CTPersonController.getSecondaryContacts(redStatus, alreadyProcessed));

    for (Id pid : orangeStatus) {
      personToUpdate.add(new Person__c(Id = pid, Health_Status__c = 'Orange'));
    }

    for (Id pid : yellowStatus) {
      personToUpdate.add(new Person__c(Id = pid, Health_Status__c = 'Yellow'));
    }
    if (personToUpdate.size() > 0) {
      update personToUpdate;
    }

    List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByPersonIds(
      statusChange
    );
    if (locationTraces != null && locationTraces.size() > 0) {
      Set<Id> locationIds = new Set<Id>();
      for (Location_Tracing__c trace : locationTraces) {
        locationIds.add(trace.Location__c);
      }
      CTLocationController.updateRedScore(locationIds);
    }
  }
}
