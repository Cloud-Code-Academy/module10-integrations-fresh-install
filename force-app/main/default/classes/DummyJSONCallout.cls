/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */
public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */
	
	@future(callout=true)

	public static void getDummyJSONUserFromId(String dummyUserId) {

		// Create HTTP request to send.
		Http http = new Http ();
		HttpRequest req = new HttpRequest();
		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.

		req.setEndpoint('https://dummyjson.com/user/' + dummyUserId);
				// Set the HTTP method to GET.

		req.setMethod('GET');

		// Send the HTTP request and get the response.
		HttpResponse response = http.send(req);

		// If the HTTP response code is successful, parse the JSON response and update the contact.

		if (response.getStatusCode() == 200) {

			//deserialize into DummyJSONUser
			DummyJSONUser bogus = (DummyJSONUser)JSON.deserialize(response.getBody(), DummyJSONUser.class);  			//Cast one variable into another

			//add all properties into the Contact obj
			Contact cont = new Contact();
			cont.DummyJSON_Id__c = bogus.id;
			cont.LastName = bogus.lastName;
			cont.Email = bogus.email;
			cont.Phone = bogus.phone;
			cont.Birthdate = bogus.birthDate;
			cont.MailingStreet = bogus.address.address;
			cont.MailingCity = bogus.address.city;
			cont.MailingPostalCode = bogus.address.postalCode;
			cont.MailingState = bogus.address.state;
			cont.MailingCountry = bogus.address.country;


			//refactor the above to call the method from question2

			//SELECT , Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry


			upsert cont DummyJSON_Id__c; //insert/update from the JSON response using the external id (dummyUserId)

		}
		
	}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */

	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {

		// Deserialize the JSON string into map of primitive data types.
		DummyJSONUser second = (DummyJSONUser)JSON.deserialize(jsonResponse, DummyJSONUser.class);

		////deserialize into DummyJSONUser
		//DummyJSONUser bogus = (DummyJSONUser)JSON.deserialize(response.getBody(), DummyJSONUser.class);  			
		//Cast one variable into another

		Contact cont2 = new Contact(); 		// Create a new contact from the JSON response.

		cont2.LastName = second.lastName;		// Set the contact fields from the JSON response.
		cont2.Email = second.email;
		cont2.Phone = second.phone;
		cont2.Birthdate = second.birthDate;
		cont2.MailingStreet = second.address.address;
		cont2.MailingCity = second.address.city;
		cont2.MailingPostalCode = second.address.postalCode;
		cont2.MailingState = second.address.state;
		cont2.MailingCountry = second.address.country;


		

		// Deserialize the address from the JSON response.

		// Set the address fields on the contact.

		return cont2;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on 
	 * the provided Salesforce Contact ID.
	 * 
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
	 * 
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field 
	 * in Salesforce to the current time.
	 * 
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	public static void postCreateDummyJSONUser(String contactId) {

		Contact cont = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];

		// Create HTTP request to send.
		HttpRequest request = new HttpRequest();
		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
		request.setEndpoint('https://dummyjson.com/users/add');
		// Set the HTTP method to POST.
		request.setMethod('POST');				
		request.setHeader('Content-Type', 'application/json');
		// Set the body using generateDummyJsonUserPayload method.					
		request.setBody('{"firstName": "Tester"}');


		// Send the HTTP request and get the response.
		Http http = new Http();
		HttpResponse response = http.send(request);

		//Log responses for debugging
		System.debug(response.getBody());
		System.debug(response.getStatusCode());
		System.debug(response.getStatus());

		// If the HTTP response code is successful, 
		if (response.getStatusCode() >= 200 || response.getStatusCode() <= 299) {
			//update the contact.
			cont.DummyJSON_Last_Updated__c = System.now();
			update cont;
			System.debug('Contact Updated: ' + cont.Id);
		} else {
			//Handle error
			System.debug('Error during callout: ' + response.getStatus());
		}

	}

	/*
	 * Question 4
	 * 
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for 
	 * user creation or update.
	 * 
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
	 * 
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
	 * 
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {

		// Query the contact to get the field values to generate the JSON payload.
		Contact cont = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];

		// Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exists.
		if (cont.FirstName == NULL) {
			cont.FirstName = 'unknown';
		}
		if (cont.LastName == NULL) {
			cont.LastName = 'unknown';
		}
		if (cont.Email == NULL) {
			cont.Email = 'unknown';
		}
		if (cont.Phone == NULL) {
			cont.Phone = 'unknown';
		}
		// Create a map of the field values.
		Map<String, Object> jsonMap = new Map<String, Object>();
		jsonMap.put('salesforceId', cont.Id);
		jsonMap.put('firstName', cont.FirstName);
		jsonMap.put('lastName', cont.LastName);
		jsonMap.put('email', cont.Email);
		jsonMap.put('phone', cont.Phone);

		// Serialize the map into a JSON string.
		String jsonPayload = JSON.serialize(jsonMap);

		// Integration data can change over time. It is a best practice to add safeguards/validation to ensure the integration does not break.

		return jsonPayload;
	}



	public class DummyJSONUser {

		public String lastName;
		public String email;
		public String id;
		public String phone;
		public Date birthDate;
		public DummyJSONUserAddress address;



		//SELECT , Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry

	}

	public class DummyJSONUserAddress {

		public String address; //"626 Main Street",
		public String city;
		public String postalCode;
		public String state;
		public String country;


	}

	/*	
		"id": 1,
  "firstName": "Emily",
  "lastName": "Johnson",
  "maidenName": "Smith",
  "age": 28,
  "gender": "female",
  "email": "emily.johnson@x.dummyjson.com",
  "phone": "+81 965-431-3024",
  "username": "emilys",
  "password": "emilyspass",
  "birthDate": "1996-5-30",
  "image": "...",
  "bloodGroup": "O-",
  "height": 193.24,
  "weight": 63.16,
  "eyeColor": "Green",
  "hair": {
    "color": "Brown",
    "type": "Curly"
  },
  "ip": "42.48.100.32",
  "address": {
    "address": "626 Main Street",
    "city": "Phoenix",
    "state": "Mississippi",
    "stateCode": "MS",
    "postalCode": "29112",
    "coordinates": {
      "lat": -77.16213,
      "lng": -92.084824
    },
    "country": "United States"
  },
  "macAddress": "47:fa:41:18:ec:eb",
  "university": "University of Wisconsin--Madison",
  "bank": {
    "cardExpire": "03/26",
    "cardNumber": "9289760655481815",
    "cardType": "Elo",
    "currency": "CNY",
    "iban": "YPUXISOBI7TTHPK2BR3HAIXL"
  },
  "company": {
    "department": "Engineering",
    "name": "Dooley, Kozey and Cronin",
    "title": "Sales Manager",
    "address": {
      "address": "263 Tenth Street",
      "city": "San Francisco",
      "state": "Wisconsin",
      "stateCode": "WI",
      "postalCode": "37657",
      "coordinates": {
        "lat": 71.814525,
        "lng": -161.150263
      },
      "country": "United States"
    }
  },
  "ein": "977-175",
  "ssn": "900-590-289",
  "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36",
  "crypto": {
    "coin": "Bitcoin",
    "wallet": "0xb9fc2fe63b2a6c003f1c324c3bfa53259162181a",
    "network": "Ethereum (ERC20)"
  },
  "role": "admin" // or "moderator", or "user"
}
  */

}