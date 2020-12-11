/**
 * @Description : Controller class for makeAppointment Component. Used for booking appointment for patient.
 *                1. It retrieves the google calendar for a particular doctor and display to medical app
 *                   admin for appointment booking.
 *                2. Once Admin clicks on "Book Appointment", a booking is created in doctor google calender and also
 *                   a case(Care plan) is created and an email goes out to patient for appointment booking confirmation
 *  
 */
public with sharing class MakeAppointmentController {
    public static Http http = new Http();
    public static HTTPResponse response;
    public static HttpRequest request;
/**
 * @Description: get the appointment price for a particular specialization
 */
@AuraEnabled
public static doctorsWithPriceDetail getAppointmentPrice(String selectedSpecialization){
    Decimal selectedPrice;
    doctorsWithPriceDetail doctorsWithPriceDetailVar = new doctorsWithPriceDetail();
    try {
        List<account> actList = [Select Id, Appointment_Price__c From Account Where type=: selectedSpecialization];
        if(!actList.isEmpty()){
            selectedPrice = actList[0].Appointment_Price__c;
        }
        List<Contact> cList = getDoctorsListDynamically(selectedSpecialization);
        doctorsWithPriceDetailVar.selectedPrice = selectedPrice;
        doctorsWithPriceDetailVar.doctorsList = cList;
    }catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    return doctorsWithPriceDetailVar;
}
/**
 * @Description: gets doctor details based on selected specialization 
 * */    
@AuraEnabled
public static doctorsWithPriceDetail getDoctors(String searchKey){
    try {
        doctorsWithPriceDetail doctorsWithPriceDetailVar = new doctorsWithPriceDetail();
        List<Contact> cList = getDoctorsListDynamically(searchKey);
        doctorsWithPriceDetailVar.doctorsList = cList;
        return doctorsWithPriceDetailVar; 
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
public class doctorsWithPriceDetail{
    @AuraEnabled
    public Decimal selectedPrice;
    @AuraEnabled  
    public List<Contact> doctorsList;
}

public static List<contact> getDoctorsListDynamically(String searchKey){
        String selectSql = 'Select Id, FirstName, LastName, Email, MobilePhone, account.type From Contact where ';
        String filterSql;
        String finalSql;
        List<Contact> doctors  = new List<Contact>();
        if((searchKey == '--Select--') || (searchKey == 'Other')){
            filterSql = 'account.recordType.developerName =' + '\'Specializations\'';
        }else{
            filterSql = 'account.recordType.developerName =' + '\'Specializations\'' + ' AND account.TYPE =' +  '\''+ searchKey+ '\'';
        }
        finalSql = selectSql + filterSql;
        doctors = database.query(finalSql);
        return doctors;
}
/**
 * @Description : pull the google calendar events for a particular doctor and for a particular date
 */
@AuraEnabled
 public static List<appointmentDetails> getEvents(String selectedDate, String selectedDoctor) {
        List<appointmentDetails> appointmentList = new List<appointmentDetails>();
       try{ 
        Contact doctorVar = (Contact)System.JSON.deserialize(selectedDoctor, Contact.class);
        String yearVar = selectedDate.subString(0,4);
        String monthVar = selectedDate.subString(5,7);
        String dayVar = selectedDate.subString(8,10);
        DateTime myDateTime = DateTime.newInstanceGMT(integer.valueOf(yearVar), integer.valueOf(monthVar), integer.valueOf(dayVar), 18, 0, 0);
        
        String formattedMax = myDateTime.formatGMT('yyyy-MM-dd\'T\'kk:mm:ss\'Z\'');
        DateTime myDateTimeMin = DateTime.newInstanceGMT(integer.valueOf(yearVar), integer.valueOf(monthVar), (integer.valueOf(dayVar) -1), 18, 0, 0);
        String formattedMin = myDateTimeMin.formatGMT('yyyy-MM-dd\'T\'kk:mm:ss\'Z\'');
        
        String urlStr = 'timeMin='+formattedMin+'&timeZone=Australia/Melbourne'+'&timeMax='+formattedMax;
        String baseUrl = 'calendar/v3/calendars/' + doctorVar.email+ '/events?' ;

        request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:GoogleAPI/'+ baseUrl + urlStr);
 
        response = http.send(request); 
        System.debug('response>>>>'+response);
        System.debug('response>>>>'+response.getBody());
        if(response.getStatusCode() == 200){
            appointmentList = parseResponse(response.getBody(), selectedDate);
        }else{
            appointmentList =  null;
        }
                 
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return appointmentList;
    }

    private static List<appointmentDetails>  parseResponse(String responeBody, String selectedDate){
        Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(responeBody);
        List<eventDetails> eventDetailsList = new List<eventDetails>();
        String emailString ;
        if(responseMap.containsKey('summary')){
            emailString = String.valueOf(responseMap.get('summary'));
        }

        if(responseMap.containsKey('items')){
            List<Object> objMap = (List<Object>)responseMap.get('items'); 
            for(Object str : objMap){
                Map<String,Object> keyMap = (Map<String,Object>)str;
                String startDateVar ;
                String endDateVar ;
                String eventSummary;
                
                if(keyMap.containsKey('summary')){
                    eventSummary = String.valueOf(keyMap.get('summary'));
                }
                if(keyMap.containsKey('start')){
                    Map<String,Object> startDateMap = (Map<String,Object>)keyMap.get('start');
                     startDateVar = String.valueOf(startDateMap.get('dateTime'));
                }
                if(keyMap.containsKey('end')){
                    Map<String,Object> startDateMap = (Map<String,Object>)keyMap.get('end');
                     endDateVar = String.valueOf(startDateMap.get('dateTime'));
                }
                eventDetailsList.add(new eventDetails(eventSummary, startDateVar,  endDateVar, emailString));
            }
        }
        System.debug('appointmentList>>>'+eventDetailsList);
        List<appointmentDetails> appointmentList = constructAppointments(eventDetailsList, selectedDate);
        return appointmentList;
    }

    public class eventDetails{
        @AuraEnabled
        public String eventSummary;
        @AuraEnabled
        public String startTime;
        @AuraEnabled
        public String endTime;
        @AuraEnabled
        public String emailValue;
        public eventDetails(String eventSummaryStr, String startTimeStr, String endTimeStr,  String emailValueStr){
            this.eventSummary = eventSummaryStr ;
            this.startTime = startTimeStr ;
            this.endTime = endTimeStr ;
            this.emailValue = emailValueStr ;
        }
    }

    public class appointmentDetails{       
        @AuraEnabled
        public Boolean isAvailable ;
        @AuraEnabled
        public String startTime;
        @AuraEnabled
        public String startTimeDisplay;
        @AuraEnabled
        public String endTime;
        @AuraEnabled
        public String endTimeDisplay;
    }
    public static List<appointmentDetails>  constructAppointments(List<eventDetails> eventDetailsList, String selectedDate){
        
        List<appointmentDetails> appointmentList = new List<appointmentDetails>();
        Map<Long,eventDetails> eventDetailsMap = new Map<Long,eventDetails>();
        for(eventDetails eDetails : eventDetailsList){
            dateTime dVar = (DateTime)Json.deserialize('"'+eDetails.startTime+'"', DateTime.class);
            String dtMelbourne = dVar.format('yyyy-MM-dd kk:mm:ss', 'Australia/Melbourne');
            DateTime dtMelbourneInDate = DateTime.valueOfGMT(dtMelbourne);
            Long eventTime = dtMelbourneInDate.getTime();
            eventDetailsMap.put(eventTime, eDetails);
        }

        DateTime selectedDateParsed = (DateTime)Json.deserialize('"'+selectedDate+'"', DateTime.class);

        integer yearVar = selectedDateParsed.year();
        integer monthVar = selectedDateParsed.month();
        integer dayVar = selectedDateParsed.day();
        DateTime dtStart = DateTime.newInstanceGMT(yearVar, monthVar, dayVar, 9, 0, 0);
        Long startTimeOfDay = dtStart.getTime();

        
            for(integer i=0; i< 16 ;i++){
                Long meetingStartHr = dtStart.getTime();
                Long meetingEndHr = dtStart.addMinutes(30).getTime();
                integer meetingStartHrVar = dtStart.hour();

                appointmentDetails detailsVar = new appointmentDetails();
                if(eventDetailsMap.containsKey(meetingStartHr)){
                    detailsVar.isAvailable = false;
                    detailsVar.startTime = String.valueOf(dtStart);
                    detailsVar.startTimeDisplay = dtStart.formatGMT('HH:mm');
                    DateTime tempVar = dtStart.addMinutes(30) ;
                    detailsVar.endTime = String.valueOf(tempVar);
                    detailsVar.endTimeDisplay = tempVar.formatGMT('HH:mm');
                    appointmentList.add(detailsVar);
                }else {
                    Boolean availableFlag = false;
                    for(eventDetails evDetails: eventDetailsMap.values()){
                        Datetime eventStartTimeParse = (DateTime)JSON.deserialize('"' + evDetails.startTime + '"', DateTime.class);
                        
                        String eventStartTimeParseString = eventStartTimeParse.format('yyyy-MM-dd kk:mm:ss', 'Australia/Melbourne');
                        
                        DateTime eventStartTimeParseDate = DateTime.valueOfGMT(eventStartTimeParseString);
                        
                        Long eventStartTime = eventStartTimeParseDate.getTime();
                        Datetime eventEndTimeParse = (DateTime)JSON.deserialize('"' + evDetails.endTime + '"', DateTime.class);
                        String eventEndTimeParseString = eventEndTimeParse.format('yyyy-MM-dd kk:mm:ss', 'Australia/Melbourne');
                        DateTime eventEndTimeParseStringDate = DateTime.valueOfGMT(eventEndTimeParseString);
                        
                        Long eventEndTime = eventEndTimeParseStringDate.getTime();
                        if((meetingStartHr > eventStartTime) && (meetingEndHr < eventEndTime)){    
                            availableFlag = false;
                            break;
                        }else if((meetingStartHr <= eventStartTime) && (meetingEndHr >= eventEndTime)){    
                            availableFlag = false;
                            break;
                        }else if((eventStartTime > meetingStartHr) && (eventEndTime > meetingEndHr) && (eventStartTime - meetingStartHr < 30*60000)){
                            availableFlag = false;
                            break;
                        }else if(( meetingStartHr >= eventStartTime) && (meetingEndHr >= eventEndTime ) && ((( meetingEndHr - eventEndTime) < 30*60000))){
                            availableFlag = false;
                            break;
                        }else{
                            availableFlag = true;
                        }
                    }
                    if(eventDetailsMap.values().isEmpty()){
                        availableFlag = true;
                    }
                    if(availableFlag){
                            detailsVar.isAvailable = true;
                            detailsVar.startTime = String.valueOf(dtStart);
                            detailsVar.startTimeDisplay = dtStart.formatGMT('HH:mm');
                            DateTime tempVar = dtStart.addMinutes(30) ;
                            detailsVar.endTime = String.valueOf(tempVar);
                            detailsVar.endTimeDisplay = tempVar.formatGMT('HH:mm');
                            appointmentList.add(detailsVar);       
                    }else{
                            System.debug('Un available time slot');
                            detailsVar.isAvailable = false;
                            detailsVar.startTime = String.valueOf(dtStart);
                            detailsVar.startTimeDisplay = dtStart.formatGMT('HH:mm');
                            DateTime tempVar = dtStart.addMinutes(30) ;
                            detailsVar.endTime = String.valueOf(tempVar);
                            detailsVar.endTimeDisplay = tempVar.formatGMT('HH:mm');
                            appointmentList.add(detailsVar);
                    }
                }
                dtStart = dtStart.addMinutes(30);
                if(dtStart.hour() == 23){
                    dtStart = dtStart.addMinutes(60);
                }
            }
        
        System.debug('appointmentList>>>>'+appointmentList);
        return appointmentList;
    }
    /**
     * @Description : Book appointment in google calendar for a particular doctor and a particular date/time
     */
    @AuraEnabled
    public static Boolean bookAppointment(String eventDetails, String selectedDoctor, String selectedPatient){
    
        Boolean successFlag = false;
    try{
        Contact doctorVar = (Contact)System.JSON.deserialize(selectedDoctor, Contact.class);    
        Patients__c patientRecord = [Select Id, First_Name__c, Last_Name__c, Mobile__c, Email__c From Patients__c Where Id =: id.valueOf(selectedPatient)];
        appointmentDetails appointmentDetailsVar = (appointmentDetails)System.JSON.deserialize(eventDetails, appointmentDetails.class);

        String startDateTime = appointmentDetailsVar.startTime;
        String endDateTime = appointmentDetailsVar.endTime;        
        DateTime startDateTimeInDateFormat = DateTime.valueOf(startDateTime);        
        DateTime endDateTimeInDateFormat = DateTime.valueOf(endDateTime);
        TimeZone targetTimezone = TimeZone.getTimeZone('Australia/Melbourne');

        String formattedStartDate = startDateTimeInDateFormat.formatGMT('yyyy-MM-dd\'T\'kk:mm:ss');
        
        String formattedEndDate = endDateTimeInDateFormat.formatGMT('yyyy-MM-dd\'T\'kk:mm:ss');
        googleCalenderRequestBody googleCalenderRequestBodyStartTime = new googleCalenderRequestBody();
        googleCalenderRequestBodyStartTime.dateTimeVar = formattedStartDate ;
        googleCalenderRequestBodyStartTime.timeZoneVar = 'Australia/Melbourne';

        googleCalenderRequestBody googleCalenderRequestBodyEndTime = new googleCalenderRequestBody();
        googleCalenderRequestBodyEndTime.dateTimeVar = formattedEndDate ;
        googleCalenderRequestBodyEndTime.timeZoneVar = 'Australia/Melbourne';

        googleCalenderRequestBodyContainer googleCalenderRequestBodyContainerVar = new googleCalenderRequestBodyContainer();
        googleCalenderRequestBodyContainerVar.startVar = googleCalenderRequestBodyStartTime;
        googleCalenderRequestBodyContainerVar.endVar = googleCalenderRequestBodyEndTime;
        googleCalenderRequestBodyContainerVar.summary = 'Appointment With ' + patientRecord.First_Name__c;

        String jsonString = JSON.serialize(googleCalenderRequestBodyContainerVar);
        jsonString = jsonString.replace('dateTimeVar', 'dateTime'); 
        jsonString = jsonString.replace('timeZoneVar', 'timeZone');
        jsonString = jsonString.replace('startVar', 'start');
        jsonString = jsonString.replace('endVar', 'end');

        String baseUrl = 'calendar/v3/calendars/' + doctorVar.email + '/events' ;
          string reuestUrl = 'https://www.googleapis.com/';          
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            //req.setEndpoint('callout:GoogleAPI/calendar/v3/calendars/singharjun84@gmail.com/events');
            req.setEndpoint('callout:GoogleAPI/' + baseUrl);
            req.setMethod('POST'); 
            req.setbody(jsonString);
            HttpResponse res = h.send(req);
            System.debug('res>>>'+res);
            if(res.getStatusCode() == 200){
                successFlag = true;
                createCarePlanAndSendConfirmation(selectedDoctor, patientRecord, eventDetails);
            }else{
                successFlag = false;
            }
            
        }catch(Exception e){
            System.debug('Issue with booking the appointment');
            successFlag = false;
        }
        return successFlag;
    }
    /**
     * @Description : Creates a Care plan(Case) record once a booking is done for a particular doctor against a particular patient
     */
    public  static void createCarePlanAndSendConfirmation(String selectedDoctor, Patients__c patientRecord, String eventDetails){

        Contact doctorVar = (Contact)System.JSON.deserialize(selectedDoctor, Contact.class);
        appointmentDetails eventDetail = (appointmentDetails)System.JSON.deserialize(eventDetails, appointmentDetails.class);
        DateTime appointmentDateTemp = DateTime.valueOf(eventDetail.startTime);
       
        TimeZone tz = UserInfo.getTimeZone();
        integer offSetVar = tz.getOffset(appointmentDateTemp)/3600000;
        DateTime appointmentDate = appointmentDateTemp.addhours(-offSetVar);
        String description = 'Appointment With : '+ patientRecord.First_Name__c + ' . Mobile Number: '+ patientRecord.Mobile__c ;

        Case newCarePlan = new Case();
        newCarePlan.ContactId = doctorVar.Id;
        newCarePlan.Patient__c = patientRecord.Id;
        newCarePlan.Appointment_Date__c = appointmentDate;
        newCarePlan.Description = description;
        newCarePlan.Patient_Email__c = patientRecord.Email__c;

        System.debug('newCarePlan>>>>'+newCarePlan);
        insert newCarePlan;
    }
    public class googleCalenderRequestBody{
        public string dateTimeVar;
        public String timeZoneVar;
    }

    public class googleCalenderRequestBodyContainer{
        public googleCalenderRequestBody startVar;
        public googleCalenderRequestBody endVar;
        public String  summary;
    }
    
}