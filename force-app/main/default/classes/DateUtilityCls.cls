public class DateUtilityCls {   
    public static Date getFutureBusinessDate(BusinessHours bh, List<Holiday> lstHolyday, Date startDte, Integer numberOfBusinessDays){
        BusinessHoursMath business = new BusinessHoursMath();
        business.setBusinessHours(bh);
        business.setHolidays(lstHolyday);
        DateTime obj;
        if(numberOfBusinessDays < 0){
            obj = business.getPreviousEndOfBusinessDayFromDate(startDte,numberOfBusinessDays);
        }else if(numberOfBusinessDays > 0){
            obj = business.getEndOfBusinessDayFromDate(startDte,numberOfBusinessDays);
        }else if(numberOfBusinessDays == 0){
            return startDte;
        }
        return date.newinstance(obj.year(), obj.month(), obj.day());
    }
    
    public static BusinessHours getBusinessHours(){        
        BusinessHours  bh = [SELECT Id, MondayEndTime, MondayStartTime, TuesdayEndTime, TuesdayStartTime, WednesdayEndTime, 
                             WednesdayStartTime, ThursdayEndTime, ThursdayStartTime, FridayEndTime, FridayStartTime, SaturdayEndTime, 
                             SaturdayStartTime, SundayEndTime, SundayStartTime FROM BusinessHours WHERE Name = 'Hippo Agency Sales'];
        return bh;
    }
    public static List<Holiday> getHolidays(){        
        List<Holiday>  lstHolyday = [SELECT Id, ActivityDate, RecurrenceType, RecurrenceDayOfMonth, RecurrenceMonthOfYear from Holiday];        
        return lstHolyday;
    }
}