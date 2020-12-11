global class MakeAppointControllerMockResponse implements HttpCalloutMock{

    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        String jsonResponse = '{'+
                      '"kind": "calendar#events",'+
                      //'"etag": "\"p32ocbh47nqtuq0g\"",'+
                      '"summary": "Arjun Singh",'+
                      '"updated": "2020-12-07T08:47:39.918Z",'+
                      '"timeZone": "Australia/Melbourne",'+
                      '"accessRole": "owner",'+
                      '"defaultReminders": [],'+
                      '"nextSyncToken": "CLDFxIe-u-0CELDFxIe-u-0CGAU=",'+
                      '"items": ['+
                      '{'+
                      '"kind": "calendar#event",'+
                      //'"etag": "\"3214659589452000\"",'+
                      '"id": "clig08kaa8sq1qjmgmok8np090",'+
                      '"status": "confirmed",'+
                      '"htmlLink": "https://www.google.com/calendar/event?eid=Y2xpZzA4a2FhOHNxMXFqbWdtb2s4bnAwOTAgc2luZ2hhcmp1bnNmQG0&ctz=Australia/Melbourne",'+
                      '"created": "2020-12-07T08:29:54.000Z",'+
                      '"updated": "2020-12-07T08:29:54.726Z",'+
                      '"creator": {'+
                      '"email": "singharjun84@gmail.com"'+
                      '},'+
                      '"organizer": {'+
                      '"email": "singharjunsf@gmail.com",'+
                      '"self": true'+
                      '},'+
                      '"start": {'+
                      '"dateTime": "2020-12-08T10:00:00+11:00",'+
                      '"timeZone": "Australia/Melbourne"'+
                      '},'+
                      '"end": {'+
                      '"dateTime": "2020-12-08T10:30:00+11:00",'+
                      '"timeZone": "Australia/Melbourne"'+
                      '},'+
                      '"iCalUID": "clig08kaa8sq1qjmgmok8np090@google.com",'+
                      '"sequence": 0,'+
                      '"reminders": {'+
                      '"useDefault": true'+
                      '}'+
                      '}'+
                      ']'+
                      '}';
        String serviceJson = '{"items":[{"id":"a0f30bd3-18a3-4b38-8ee1-04d96cc50efb","type": "Service","code": "REGULAR","category" : "DOMESTIC_LETTER","items": [{"id": "1bb2e537-24b1-4d22-a644-90556620358e","type": "DeliveryEstimate","code": "FIXED","minimum": 4,"maximum": 7,"estimate": "Delivered in 4-7 days","unit": "Day"}]}]} ';
        //String errJson = '{"code":"400","status":"ValidationFailed","message":"Bad request: invalid inputs.","field_error":[{"code":"CPDT-002-PARAM_INVALID","defaultMessage":"A domestic postcode must consist of 4 numeric digits.","field":"fromPostcode","rejectedValue":"adsfadfs"}]}';        
        res.setHeader('Content-Type', 'application/json');
        res.setBody(jsonResponse);        
        res.setStatusCode(200);
        return res;
    }
}