@IsTest
public with sharing class MakeAppointmentControllerTest {
    @testSetup
    static void setupTestData() {
        Id specializationRecordId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Specializations').getRecordTypeId();
        Account actRecord = new Account();
        actRecord.name = 'Test Account';
        actRecord.Appointment_Price__c = 100;
        actRecord.Type= 'Cardiology';
        actRecord.recordTypeId = specializationRecordId;
        insert actRecord;

        contact contactRecord = new contact();
        contactRecord.FirstName = 'Test';
        contactRecord.LastName = 'Test';
        contactRecord.Email = 'Test@test.com';
        contactRecord.accountId = actRecord.Id;
        insert contactRecord;

        Patients__c patient = new Patients__c();
        patient.First_Name__c = 'Pname';
        patient.Last_Name__c = 'PLast';
        patient.Email__c = 'Pname@gmail.com';
        insert patient;
    }
    
	static testMethod void getEventTest() {
        Test.setMock(HttpCalloutMock.class, new MakeAppointControllerMockResponse());
        String selectedDate = '2020-12-11';
        contact selectedDoctorVar = [Select Id , Email from Contact where email='Test@test.com'];
        
        String selectedSpecialization = 'Cardiology';
        
        string selectedDoctor = System.JSON.Serialize(selectedDoctorVar);
        List<MakeAppointmentController.appointmentDetails> evDetail = new List<MakeAppointmentController.appointmentDetails>();

        Test.startTest();
        MakeAppointmentController.getAppointmentPrice(selectedSpecialization);
        MakeAppointmentController.getDoctors('--Select--');
        evDetail =  MakeAppointmentController.getEvents(selectedDate, selectedDoctor);
        Test.stopTest();
        System.assert(evDetail != null);
    }
    static testMethod void bookAppointmentTest() {
        Test.setMock(HttpCalloutMock.class, new MakeAppointControllerMockResponse());
        String selectedDate = '2020-12-11';
        contact selectedDoctorVar = [Select Id , Email from Contact where email='Test@test.com'];
        Patients__c patient = [Select Id, Email__c from Patients__c where email__c='Pname@gmail.com'];
        
        String selectedDoctor = System.JSON.Serialize(selectedDoctorVar);
        String selectedPatient = patient.Id;
        String eventDetails = '{"endTime":"2020-12-09 11:00:00","endTimeDisplay":"11:00","isAvailable":true,"startTime":"2020-12-09 10:30:00","startTimeDisplay":"10:30"}';
        Test.startTest();
            MakeAppointmentController.bookAppointment(eventDetails, selectedDoctor, selectedPatient);
        Test.stopTest();
        case newCarePlan = [Select Id from Case where Patient__c =: id.valueOf(selectedPatient)];
        system.assert(newCarePlan != null);
    }
}