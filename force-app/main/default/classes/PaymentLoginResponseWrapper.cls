public class PaymentLoginResponseWrapper {
    public String module_name{get;set;}
    public name_value_list name_value_list{get;set;}
    public String id{get;set;}
    public class user_number_seperator{
        public String name{get;set;}
        public String value{get;set;}
    }
    public class user_name{
        public String value{get;set;}
        public String name{get;set;}
    }
    public class user_language{
        public String value{get;set;}
        public String name{get;set;}
    }
    public class user_is_admin{
        public Boolean value{get;set;}
        public String name{get;set;}
    }
    public class user_id{
        public String value{get;set;}
        public String name{get;set;}
    }
    public class user_default_timeformat{
        public String name{get;set;}
        public String value{get;set;}
    }
    public class user_default_team_id{
        public String name{get;set;}
        public String value{get;set;}
    }
    public class user_default_dateformat{
        public String value{get;set;}
        public String name{get;set;}
    }
    public class user_decimal_seperator{
        public String name{get;set;}
        public String value{get;set;}
    }
    public class user_currency_name{
        public String name{get;set;}
        public String value{get;set;}
    }
    public class user_currency_id{
        public String value{get;set;}
        public String name{get;set;}
    }
    public class name_value_list{
        public user_number_seperator user_number_seperator{get;set;}
        public user_default_timeformat user_default_timeformat{get;set;}
        public user_decimal_seperator user_decimal_seperator{get;set;}
        public user_default_dateformat user_default_dateformat{get;set;}
        public user_default_team_id user_default_team_id{get;set;}
        public mobile_max_list_entries mobile_max_list_entries{get;set;}
        public user_is_admin user_is_admin{get;set;}
        public user_currency_id user_currency_id{get;set;}
        public user_language user_language{get;set;}
        public mobile_max_subpanel_entries mobile_max_subpanel_entries{get;set;}
        public user_name user_name{get;set;}
        public user_currency_name user_currency_name{get;set;}
        public user_id user_id{get;set;}
    }
    public class mobile_max_subpanel_entries{
        public String name{get;set;}
        public String value{get;set;}
    }
    public class mobile_max_list_entries{
        public String name{get;set;}
        public String value{get;set;}
    }
}