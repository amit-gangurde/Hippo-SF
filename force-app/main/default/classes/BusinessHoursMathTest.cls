@isTest
public with sharing class BusinessHoursMathTest {
    
    @isTest
	static public void testConstructor() {
		//create Mon - Fri 9am - 5pm business hours, and increase by 1 to test correctness
		BusinessHours businessHours = new BusinessHours(
			MondayStartTime = Time.newInstance(10, 0, 0, 0),
			MondayEndTime = Time.newInstance(17, 0, 0, 0),
			TuesdayStartTime = Time.newInstance(11, 0, 0, 0),
			TuesdayEndTime = Time.newInstance(17, 0, 0, 0),
			WednesdayStartTime = Time.newInstance(12, 0, 0, 0),
			WednesdayEndTime = Time.newInstance(17, 0, 0, 0),
			ThursdayStartTime = Time.newInstance(13, 0, 0, 0),
			ThursdayEndTime = Time.newInstance(17, 0, 0, 0),
			FridayStartTime = Time.newInstance(14, 0, 0, 0),
			FridayEndTime = Time.newInstance(17, 0, 0, 0),
			IsActive = true,
			IsDefault = true
		);
		//insert businessHours; NO DML Allowed, use the setBusinessHours for testing.
		
		//holidays are outside the scope of seeAllData, so lets use setHolidays as well
		List<Holiday> holidays = new List<Holiday>();
		holidays.add(new Holiday(
				//Christmas Eve on thursday
				Name = 'Christmas Eve',
				ActivityDate = Date.parse('12/24/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 24
			)
		);
		holidays.add(new Holiday(
				//Christmas on friday
				Name = 'Christmas',
				ActivityDate = Date.parse('12/25/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 25
			)
		);
		holidays.add(new Holiday(
				//singular Holiday event, on the following Monday
				Name = 'Bob\'s Birthday',
				ActivityDate = Date.parse('12/28/2020') 
			)
		);
		
		Test.startTest();
		
		BusinessHoursMath businessHoursMath = new BusinessHoursMath().setBusinessHours(businessHours).setHolidays(holidays);
		
		system.assertEquals(null, businessHoursMath.businessDays[0].startTime);
		system.assertEquals(null, businessHoursMath.businessDays[0].endTime);
		system.assertEquals(false, businessHoursMath.businessDays[0].isBusinessDay);
		system.assertEquals(Time.newInstance(10,0,0,0) , businessHoursMath.businessDays[1].startTime);
		system.assertEquals(Time.newInstance(17,0,0,0), businessHoursMath.businessDays[1].endTime);
		system.assertEquals(true, businessHoursMath.businessDays[1].isBusinessDay);
		system.assertEquals(Time.newInstance(11,0,0,0) , businessHoursMath.businessDays[2].startTime);
		system.assertEquals(Time.newInstance(17,0,0,0), businessHoursMath.businessDays[2].endTime);
		system.assertEquals(true, businessHoursMath.businessDays[2].isBusinessDay);
		system.assertEquals(Time.newInstance(12,0,0,0) , businessHoursMath.businessDays[3].startTime);
		system.assertEquals(Time.newInstance(17,0,0,0), businessHoursMath.businessDays[3].endTime);
		system.assertEquals(true, businessHoursMath.businessDays[3].isBusinessDay);
		system.assertEquals(Time.newInstance(13,0,0,0) , businessHoursMath.businessDays[4].startTime);
		system.assertEquals(Time.newInstance(17,0,0,0), businessHoursMath.businessDays[4].endTime);
		system.assertEquals(true, businessHoursMath.businessDays[4].isBusinessDay);
		system.assertEquals(Time.newInstance(14,0,0,0) , businessHoursMath.businessDays[5].startTime);
		system.assertEquals(Time.newInstance(17,0,0,0), businessHoursMath.businessDays[5].endTime);
		system.assertEquals(true, businessHoursMath.businessDays[5].isBusinessDay);
		system.assertEquals(null, businessHoursMath.businessDays[6].startTime);
		system.assertEquals(null, businessHoursMath.businessDays[6].endTime);
		system.assertEquals(false, businessHoursMath.businessDays[0].isBusinessDay);

		system.assertEquals(3, businessHoursMath.holidays.size());//we have em, so lets continue


		Test.stopTest();
	}

	@isTest(SeeAllData=false)
	static public void testIsBusinessDay() {
		Date testDate = Date.parse('12/22/2020'); //Tuesday
		//create Mon - Fri 9am - 5pm business hours, and increase by 1 to test correctness
		BusinessHours businessHours = new BusinessHours(
			MondayStartTime = Time.newInstance(10, 0, 0, 0),
			MondayEndTime = Time.newInstance(17, 0, 0, 0),
			TuesdayStartTime = Time.newInstance(11, 0, 0, 0),
			TuesdayEndTime = Time.newInstance(18, 0, 0, 0),
			WednesdayStartTime = Time.newInstance(12, 0, 0, 0),
			WednesdayEndTime = Time.newInstance(19, 0, 0, 0),
			ThursdayStartTime = Time.newInstance(13, 0, 0, 0),
			ThursdayEndTime = Time.newInstance(20, 0, 0, 0),
			FridayStartTime = Time.newInstance(14, 0, 0, 0),
			FridayEndTime = Time.newInstance(21, 0, 0, 0),
			IsActive = true,
			IsDefault = true
		);
		//insert businessHours; NO DML Allowed, use the setBusinessHours for testing.
		
		//holidays are outside the scope of seeAllData, so lets use setHolidays as well
		List<Holiday> holidays = new List<Holiday>();
		holidays.add(new Holiday(
				//Christmas Eve on thursday
				Name = 'Christmas Eve',
				ActivityDate = Date.parse('12/24/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 24
			)
		);
		holidays.add(new Holiday(
				//Christmas on Friday
				Name = 'Christmas',
				ActivityDate = Date.parse('12/25/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 25
			)
		);
		holidays.add(new Holiday(
				//singular Holiday event, on the following wednesday
				Name = 'Bob\'s Birthday',
				ActivityDate = Date.parse('12/28/2020') 
			)
		);
		
		Test.startTest();
		BusinessHoursMath businessHoursMath = new BusinessHoursMath().setBusinessHours(businessHours).setHolidays(holidays);
		//lets run the week and see if things are what we want
		system.debug('***BROKE');
		system.assertEquals(true , businessHoursMath.isBusinessDay(Date.parse('12/23/2020')));//wednesday
		system.assertEquals(false, businessHoursMath.isBusinessDay(Date.parse('12/24/2020')));//Thursday - Christmas Eve
		system.assertEquals(false, businessHoursMath.isBusinessDay(Date.parse('12/25/2020')));//Friday - Chrismas
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/26/2020')));//Saturday - Weekend
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/27/2020')));//Sunday - Weekend
		system.assertEquals(false, businessHoursMath.isBusinessDay(Date.parse('12/28/2020')));//Monday - Bob's Birthday
		//system.assertEquals(false, businessHoursMath.isBusinessDay(Date.parse('12/29/2020'))); //Tuesday 
		
		
		//lets check our yearly
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/25/2020'))); //Chrismas
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/25/2020'))); //Chrismas
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/25/2020'))); //Chrismas
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/25/2020'))); //Chrismas
		system.assertEquals(false , businessHoursMath.isBusinessDay(Date.parse('12/25/2020'))); //Chrismas

	Test.stopTest();
	}

	@isTest(SeeAllData=false)
	static public void testgetEndOfBusinessDayFromDate() {
		Date testDate = Date.parse('12/22/2020'); //Tuesday
		//create Mon - Fri 9am - 5pm business hours, and increase Start by 1 to test correctness
		BusinessHours businessHours = new BusinessHours(
			MondayStartTime = Time.newInstance(10, 0, 0, 0),
			MondayEndTime = Time.newInstance(17, 0, 0, 0),
			TuesdayStartTime = Time.newInstance(10, 0, 0, 0),
			TuesdayEndTime = Time.newInstance(17, 0, 0, 0),
			WednesdayStartTime = Time.newInstance(10, 0, 0, 0),
			WednesdayEndTime = Time.newInstance(17, 0, 0, 0),
			ThursdayStartTime = Time.newInstance(10, 0, 0, 0),
			ThursdayEndTime = Time.newInstance(17, 0, 0, 0),
			FridayStartTime = Time.newInstance(10, 0, 0, 0),
			FridayEndTime = Time.newInstance(17, 0, 0, 0),
			IsActive = true,
			IsDefault = true
		);
		//insert businessHours; NO DML Allowed, use the setBusinessHours for testing.
		
		//holidays are outside the scope of seeAllData, so lets use setHolidays as well
		List<Holiday> holidays = new List<Holiday>();
		holidays.add(new Holiday(
				//Christmas Eve on Thursday
				Name = 'Christmas Eve',
				ActivityDate = Date.parse('12/24/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 24
			)
		);
		holidays.add(new Holiday(
				//Christmas on Friday
				Name = 'Christmas',
				ActivityDate = Date.parse('12/25/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 25
			)
		);
		holidays.add(new Holiday(
				//singular Holiday event, on the following Monday
				Name = 'Bob\'s Birthday',
				ActivityDate = Date.parse('12/28/2020') 
			)
		);
		
		Test.startTest();
		BusinessHoursMath businessHoursMath = new BusinessHoursMath().setBusinessHours(businessHours).setHolidays(holidays);

		//we should get some good business day math now. 
		system.assertEquals(DateTime.newInstance(Date.parse('12/23/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getEndOfBusinessDayFromDate(Date.parse('12/23/2020'), 0));
		system.assertEquals(DateTime.newInstance(Date.parse('12/29/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getEndOfBusinessDayFromDate(Date.parse('12/23/2020'), 1)); 
		system.assertEquals(DateTime.newInstance(Date.parse('12/30/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getEndOfBusinessDayFromDate(Date.parse('12/23/2020'), 2));  
		system.assertEquals(DateTime.newInstance(Date.parse('12/31/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getEndOfBusinessDayFromDate(Date.parse('12/23/2020'), 3)); 
		system.assertEquals(DateTime.newInstance(Date.parse('01/01/2021'), Time.newInstance(17,0,0,0)), businessHoursMath.getEndOfBusinessDayFromDate(Date.parse('12/23/2020'), 4));

		Test.stopTest();
	}
    
    @isTest(SeeAllData=false)
	static public void testgetPreviousEndOfBusinessDayFromDate() {
		Date testDate = Date.parse('12/22/2020'); //Tuesday
		//create Mon - Fri 9am - 5pm business hours, and increase Start by 1 to test correctness
		BusinessHours businessHours = new BusinessHours(
			MondayStartTime = Time.newInstance(10, 0, 0, 0),
			MondayEndTime = Time.newInstance(17, 0, 0, 0),
			TuesdayStartTime = Time.newInstance(10, 0, 0, 0),
			TuesdayEndTime = Time.newInstance(17, 0, 0, 0),
			WednesdayStartTime = Time.newInstance(10, 0, 0, 0),
			WednesdayEndTime = Time.newInstance(17, 0, 0, 0),
			ThursdayStartTime = Time.newInstance(10, 0, 0, 0),
			ThursdayEndTime = Time.newInstance(17, 0, 0, 0),
			FridayStartTime = Time.newInstance(10, 0, 0, 0),
			FridayEndTime = Time.newInstance(17, 0, 0, 0),
			IsActive = true,
			IsDefault = true
		);
		//insert businessHours; NO DML Allowed, use the setBusinessHours for testing.
		
		//holidays are outside the scope of seeAllData, so lets use setHolidays as well
		List<Holiday> holidays = new List<Holiday>();
		holidays.add(new Holiday(
				//Christmas Eve on Thursday
				Name = 'Christmas Eve',
				ActivityDate = Date.parse('12/24/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 24
			)
		);
		holidays.add(new Holiday(
				//Christmas on Friday
				Name = 'Christmas',
				ActivityDate = Date.parse('12/25/2020'),
				RecurrenceType = 'RecursYearly',
				RecurrenceMonthOfYear = 'December',
				RecurrenceDayOfMonth = 25
			)
		);
		holidays.add(new Holiday(
				//singular Holiday event, on the following Monday
				Name = 'Bob\'s Birthday',
				ActivityDate = Date.parse('12/28/2020') 
			)
		);
		
		Test.startTest();
		BusinessHoursMath businessHoursMath = new BusinessHoursMath().setBusinessHours(businessHours).setHolidays(holidays);

		system.assertEquals(DateTime.newInstance(Date.parse('12/23/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getPreviousEndOfBusinessDayFromDate(Date.parse('12/23/2020'), 0));
		system.assertEquals(DateTime.newInstance(Date.parse('12/22/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getPreviousEndOfBusinessDayFromDate(Date.parse('12/23/2020'), -1)); 
		system.assertEquals(DateTime.newInstance(Date.parse('12/21/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getPreviousEndOfBusinessDayFromDate(Date.parse('12/23/2020'), -2));  
		system.assertEquals(DateTime.newInstance(Date.parse('12/18/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getPreviousEndOfBusinessDayFromDate(Date.parse('12/23/2020'), -3)); 
		system.assertEquals(DateTime.newInstance(Date.parse('12/17/2020'), Time.newInstance(17,0,0,0)), businessHoursMath.getPreviousEndOfBusinessDayFromDate(Date.parse('12/23/2020'), -4));

		Test.stopTest();
	}
    
}