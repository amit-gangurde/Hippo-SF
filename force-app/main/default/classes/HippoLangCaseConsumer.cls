public class HippoLangCaseConsumer {
    public static void updateCases(List<ID> ids){
        // Get claims based on the IDs
        List<Case> cases = [
            SELECT Loss_Description__c, Damage_Description__c,Location__c, Cause__c, Origin__c
            FROM Case
            WHERE (Id IN :ids) AND RecordTypeId IN (SELECT Id From RecordType WHERE Name=:'Claim')];
        String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYW5nX2tleSI6Ii9KSGNHVU1MNUhXRUp4NTZHdHY5V2JZZ1UwdmE4MUdCNkdhK3JSTXRrUkE9IiwibmFtZSI6IkFQSSB0b2tlbiIsImRvbWFpbiI6ImhpcHBvLTk0ODU2MjAiLCJhdWQiOiJMYW5nLmFpIEFQSSIsImlzcyI6IkxhbmcuYWkifQ._zWuZif4X8ezaS7RmjxRytpdGTQqz4NWpOU1keazlNo';
        String project_id = 'Zjozc8YQtNVOBcRh';
        LangClient client = new LangClient('hippo.lang.ai', token, project_id);

        List<String> locations = new List<String>{
            'Entire House', 'Roof', 'Roof/Interior', 'Roof/Fence',
            'Kitchen', '2nd Floor Bathroom', 'Master Bathroom',
            '1st Floor Bathroom', 'Guest Bathroom', 'Bathroom',
            'Basement', 'Living Room', 'Family Room', 'Dining Room',
            '2nd Floor Master Bedroom', '2nd Floor Bedroom',
            'Master Bedroom', '1st Floor Bedroom', 'Guest Bedroom',
            'Bedroom', 'Ceiling', 'Ceiling Collapse', 'Shower',
            'Utility Room', 'Laundry Room', 'Hallway', 'Entire House (Steal)',
            'Storage Unit', 'Floors', 'Wall', 'Garage', 'Chimney',
            'EBSL', 'Water Heater', 'Septic Tank', 'Electrical Panel', 
            'Equipment Breakdown', 'Window', 'Door', 'Glass Door',
            'Vehicle', 'Pool', 'Backyard/Patio', 'Porch/Deck',
            'Balcony', 'Driveway', 'Street', 'Neighbor Unit',
            'Neighbor\'s Yard', 'Attic', 'Closet/Cabinet',
            'Foundation', 'Slab', 'Garage Door', 'Gate', 'Food', 'Fence'
        };
        List<String> causes = new List<String>{
            'Cause: Storm&Wind/Roof Damage', 'Cause: Weight of Snow',
            'Cause: Storm', 'Cause: Wildfire', 'Cause: Fire',
            'Cause: Lightning', 'Cause: Rain', 'Cause: Freeze',
            'Cause: Wind', 'Cause: Tree', 'Cause: Roof', 'Cause: Tree Root',
            'Cause: Water Pipe', 'Cause: Plumbing Leak', 'Cause: Leak',
            'Cause: Service Line', 'Cause: Sewer line', 'Cause: Sewage Line/Pipe',
            'Cause: Sump Pump', 'Cause: Pipe', 'Cause: Water (Unknown)',
            'Cause: Gas Leak', 'Cause: Swamp Cooler', 'Cause: A/C',
            'Cause: Septic Tank', 'Cause: Boiler', 'Cause: Heater',
            'Cause: Washing Machine', 'Cause: Stove Top', 'Cause: Dishwasher',
            'Cause: Dryer', 'Cause: Refrigerator', 'Cause: Oven', 'Cause: Water Heater',
            'Cause: Vehicle Hit', 'Cause: Pool Equipment', 'Cause: Pool Pipe/Leak',
            'Cause: Bathtub', 'Cause: Toilet', 'Cause: Sink', 'Cause: Water Faucet',
            'Cause: Clogged Drain', 'Cause: Drain', 'Cause: Theft', 'Cause: Jewelry Lost',
            'Cause: Ice Maker', 'Cause: Microwave', 'Cause: Power Outage/Surge',
            'Cause: Slab Leak', 'Cause: Foundation Issues', 'Cause: Dog',
            'Cause: Animals', 'Cause: Driver Hit Fence', 'Cause: Fence'
        };
        List<String> origins = new List<String>{
            'Origin: Fire (Entire House)', 'Origin: Wildfire',
            'Origin: Lightning', 'Origin: Roof', 'Origin: Roof Leak',
            'Origin: Water Pipe', 'Origin: Water Pipe', 'Origin: Basement Rain',
            'Origin: Plumbing Leak', 'Origin: Leak', 'Origin: Shower Plumbing',
            'Origin: Service Line', 'Origin: Sewer Line', 'Origin: Sewage Line/Pipe',
            'Origin: Sump Pump', 'Origin: Water (Unknown)', 'Origin: Gas Leak',
            'Origin: A/C', 'Origin: Septic Tank', 'Origin: Boiler', 'Origin: Heater',
            'Origin: Washing Machine', 'Origin: Stove Top', 'Origin: Dishwasher',
            'Origin: Dryer', 'Origin: Refrigerator', 'Origin: Oven', 'Origin: Water Heater',
            'Origin: Mold', 'Origin: Window', 'Origin: Computer', 'Origin: Exterior Home',
            'Origin: Vehicle Hit', 'Origin: Pool Equipment', 'Origin: Pool Pipe/Leak',
            'Origin: Bathtub', 'Origin: Shower', 'Origin: Shower', 'Origin: Toilet',
            'Origin: Sink', 'Origin: Water Faucet', 'Origin: Clogged Drain',
            'Origin: Drain', 'Origin: Theft', 'Origin: Jewelry Lost', 'Origin: Ice Maker',
            'Origin: Microwave', 'Origin: Slab Leak', 'Origin: Foundation Issues',
            'Origin: Dog', 'Origin: Driver Hit Fence', 'Origin: Fence'
        };
        for (Case c : cases) {
            String text = c.Loss_Description__c + '. ' + c.Damage_Description__c;
            List<String> tags = client.analyze(text);
            for (String location : locations) {
                if (tags.contains(location)) {
                    system.debug('Has location: ' + location + '!');
                    c.Location__c = location;
                    break;
                }
            }
            for (String cause : causes) {
                if (tags.contains(cause)) {
                    system.debug('Has cause: ' + cause + '!');
                    c.Cause__c = cause;
                    break;
                }
            }
            for (String origin : origins) {
                if (tags.contains(origin)) {
                    system.debug('Has origin: ' + origin + '!');
                    c.Origin__c = origin;
                    break;
                }
            }
        }
        update cases;
    }
    @future(callout=true)
    public static void process(List<ID> ids) {   
        updateCases(ids);
    }
}


//Old Class
/*public class HippoLangCaseConsumer {
    @future(callout=true)
    public static void process(List<ID> ids) {   
        // Get claims based on the IDs
        List<Case> cases = [
            SELECT Loss_Description__c, Damage_Description__c,Location__c, Cause__c, Origin__c
            FROM Case
            WHERE (Id IN :ids) AND RecordTypeId IN (SELECT Id From RecordType WHERE Name=:'Claim')];
        String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYW5nX2tleSI6Ii9KSGNHVU1MNUhXRUp4NTZHdHY5V2JZZ1UwdmE4MUdCNkdhK3JSTXRrUkE9IiwibmFtZSI6IkFQSSB0b2tlbiIsImRvbWFpbiI6ImhpcHBvLTk0ODU2MjAiLCJhdWQiOiJMYW5nLmFpIEFQSSIsImlzcyI6IkxhbmcuYWkifQ._zWuZif4X8ezaS7RmjxRytpdGTQqz4NWpOU1keazlNo';
        String project_id = 'Zjozc8YQtNVOBcRh';
        LangClient client = new LangClient('hippo.lang.ai', token, project_id);

        List<String> locations = new List<String>{
            'Entire House', 'Roof', 'Roof/Interior', 'Roof/Fence',
            'Kitchen', '2nd Floor Bathroom', 'Master Bathroom',
            '1st Floor Bathroom', 'Guest Bathroom', 'Bathroom',
            'Basement', 'Living Room', 'Family Room', 'Dining Room',
            '2nd Floor Master Bedroom', '2nd Floor Bedroom',
            'Master Bedroom', '1st Floor Bedroom', 'Guest Bedroom',
            'Bedroom', 'Ceiling', 'Ceiling Collapse', 'Shower',
            'Utility Room', 'Laundry Room', 'Hallway', 'Entire House (Steal)',
            'Storage Unit', 'Floors', 'Wall', 'Garage', 'Chimney',
            'EBSL', 'Water Heater', 'Septic Tank', 'Electrical Panel', 
            'Equipment Breakdown', 'Window', 'Door', 'Glass Door',
            'Vehicle', 'Pool', 'Backyard/Patio', 'Porch/Deck',
            'Balcony', 'Driveway', 'Street', 'Neighbor Unit',
            'Neighbor\'s Yard', 'Attic', 'Closet/Cabinet',
            'Foundation', 'Slab', 'Garage Door', 'Gate', 'Food', 'Fence'
        };
        List<String> causes = new List<String>{
            'Cause: Storm&Wind/Roof Damage', 'Cause: Weight of Snow',
            'Cause: Storm', 'Cause: Wildfire', 'Cause: Fire',
            'Cause: Lightning', 'Cause: Rain', 'Cause: Freeze',
            'Cause: Wind', 'Cause: Tree', 'Cause: Roof', 'Cause: Tree Root',
            'Cause: Water Pipe', 'Cause: Plumbing Leak', 'Cause: Leak',
            'Cause: Service Line', 'Cause: Sewer line', 'Cause: Sewage Line/Pipe',
            'Cause: Sump Pump', 'Cause: Pipe', 'Cause: Water (Unknown)',
            'Cause: Gas Leak', 'Cause: Swamp Cooler', 'Cause: A/C',
            'Cause: Septic Tank', 'Cause: Boiler', 'Cause: Heater',
            'Cause: Washing Machine', 'Cause: Stove Top', 'Cause: Dishwasher',
            'Cause: Dryer', 'Cause: Refrigerator', 'Cause: Oven', 'Cause: Water Heater',
            'Cause: Vehicle Hit', 'Cause: Pool Equipment', 'Cause: Pool Pipe/Leak',
            'Cause: Bathtub', 'Cause: Toilet', 'Cause: Sink', 'Cause: Water Faucet',
            'Cause: Clogged Drain', 'Cause: Drain', 'Cause: Theft', 'Cause: Jewelry Lost',
            'Cause: Ice Maker', 'Cause: Microwave', 'Cause: Power Outage/Surge',
            'Cause: Slab Leak', 'Cause: Foundation Issues', 'Cause: Dog',
            'Cause: Animals', 'Cause: Driver Hit Fence', 'Cause: Fence'
        };
        List<String> origins = new List<String>{
            'Origin: Fire (Entire House)', 'Origin: Wildfire',
            'Origin: Lightning', 'Origin: Roof', 'Origin: Roof Leak',
            'Origin: Water Pipe', 'Origin: Water Pipe', 'Origin: Basement Rain',
            'Origin: Plumbing Leak', 'Origin: Leak', 'Origin: Shower Plumbing',
            'Origin: Service Line', 'Origin: Sewer Line', 'Origin: Sewage Line/Pipe',
            'Origin: Sump Pump', 'Origin: Water (Unknown)', 'Origin: Gas Leak',
            'Origin: A/C', 'Origin: Septic Tank', 'Origin: Boiler', 'Origin: Heater',
            'Origin: Washing Machine', 'Origin: Stove Top', 'Origin: Dishwasher',
            'Origin: Dryer', 'Origin: Refrigerator', 'Origin: Oven', 'Origin: Water Heater',
            'Origin: Mold', 'Origin: Window', 'Origin: Computer', 'Origin: Exterior Home',
            'Origin: Vehicle Hit', 'Origin: Pool Equipment', 'Origin: Pool Pipe/Leak',
            'Origin: Bathtub', 'Origin: Shower', 'Origin: Shower', 'Origin: Toilet',
            'Origin: Sink', 'Origin: Water Faucet', 'Origin: Clogged Drain',
            'Origin: Drain', 'Origin: Theft', 'Origin: Jewelry Lost', 'Origin: Ice Maker',
            'Origin: Microwave', 'Origin: Slab Leak', 'Origin: Foundation Issues',
            'Origin: Dog', 'Origin: Driver Hit Fence', 'Origin: Fence'
        };
        for (Case c : cases) {
            String text = c.Loss_Description__c + '. ' + c.Damage_Description__c;
            List<String> tags = client.analyze(text);
            for (String location : locations) {
                if (tags.contains(location)) {
                    system.debug('Has location: ' + location + '!');
                    c.Location__c = location;
                    break;
                }
            }
            for (String cause : causes) {
                if (tags.contains(cause)) {
                    system.debug('Has cause: ' + cause + '!');
                    c.Cause__c = cause;
                    break;
                }
            }
            for (String origin : origins) {
                if (tags.contains(origin)) {
                    system.debug('Has origin: ' + origin + '!');
                    c.Origin__c = origin;
                    break;
                }
            }
        }
        update cases;
    }
     public static void processSync(List<ID> ids) {   
        // Get claims based on the IDs
        List<Case> cases = [
            SELECT Loss_Description__c, Damage_Description__c,Location__c, Cause__c, Origin__c
            FROM Case
            WHERE (Id IN :ids) AND RecordTypeId IN (SELECT Id From RecordType WHERE Name=:'Claim')];
        String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYW5nX2tleSI6Ii9KSGNHVU1MNUhXRUp4NTZHdHY5V2JZZ1UwdmE4MUdCNkdhK3JSTXRrUkE9IiwibmFtZSI6IkFQSSB0b2tlbiIsImRvbWFpbiI6ImhpcHBvLTk0ODU2MjAiLCJhdWQiOiJMYW5nLmFpIEFQSSIsImlzcyI6IkxhbmcuYWkifQ._zWuZif4X8ezaS7RmjxRytpdGTQqz4NWpOU1keazlNo';
        String project_id = 'Zjozc8YQtNVOBcRh';
        LangClient client = new LangClient('hippo.lang.ai', token, project_id);

        List<String> locations = new List<String>{
            'Entire House', 'Roof', 'Roof/Interior', 'Roof/Fence',
            'Kitchen', '2nd Floor Bathroom', 'Master Bathroom',
            '1st Floor Bathroom', 'Guest Bathroom', 'Bathroom',
            'Basement', 'Living Room', 'Family Room', 'Dining Room',
            '2nd Floor Master Bedroom', '2nd Floor Bedroom',
            'Master Bedroom', '1st Floor Bedroom', 'Guest Bedroom',
            'Bedroom', 'Ceiling', 'Ceiling Collapse', 'Shower',
            'Utility Room', 'Laundry Room', 'Hallway', 'Entire House (Steal)',
            'Storage Unit', 'Floors', 'Wall', 'Garage', 'Chimney',
            'EBSL', 'Water Heater', 'Septic Tank', 'Electrical Panel', 
            'Equipment Breakdown', 'Window', 'Door', 'Glass Door',
            'Vehicle', 'Pool', 'Backyard/Patio', 'Porch/Deck',
            'Balcony', 'Driveway', 'Street', 'Neighbor Unit',
            'Neighbor\'s Yard', 'Attic', 'Closet/Cabinet',
            'Foundation', 'Slab', 'Garage Door', 'Gate', 'Food', 'Fence'
        };
        List<String> causes = new List<String>{
            'Cause: Storm&Wind/Roof Damage', 'Cause: Weight of Snow',
            'Cause: Storm', 'Cause: Wildfire', 'Cause: Fire',
            'Cause: Lightning', 'Cause: Rain', 'Cause: Freeze',
            'Cause: Wind', 'Cause: Tree', 'Cause: Roof', 'Cause: Tree Root',
            'Cause: Water Pipe', 'Cause: Plumbing Leak', 'Cause: Leak',
            'Cause: Service Line', 'Cause: Sewer line', 'Cause: Sewage Line/Pipe',
            'Cause: Sump Pump', 'Cause: Pipe', 'Cause: Water (Unknown)',
            'Cause: Gas Leak', 'Cause: Swamp Cooler', 'Cause: A/C',
            'Cause: Septic Tank', 'Cause: Boiler', 'Cause: Heater',
            'Cause: Washing Machine', 'Cause: Stove Top', 'Cause: Dishwasher',
            'Cause: Dryer', 'Cause: Refrigerator', 'Cause: Oven', 'Cause: Water Heater',
            'Cause: Vehicle Hit', 'Cause: Pool Equipment', 'Cause: Pool Pipe/Leak',
            'Cause: Bathtub', 'Cause: Toilet', 'Cause: Sink', 'Cause: Water Faucet',
            'Cause: Clogged Drain', 'Cause: Drain', 'Cause: Theft', 'Cause: Jewelry Lost',
            'Cause: Ice Maker', 'Cause: Microwave', 'Cause: Power Outage/Surge',
            'Cause: Slab Leak', 'Cause: Foundation Issues', 'Cause: Dog',
            'Cause: Animals', 'Cause: Driver Hit Fence', 'Cause: Fence'
        };
        List<String> origins = new List<String>{
            'Origin: Fire (Entire House)', 'Origin: Wildfire',
            'Origin: Lightning', 'Origin: Roof', 'Origin: Roof Leak',
            'Origin: Water Pipe', 'Origin: Water Pipe', 'Origin: Basement Rain',
            'Origin: Plumbing Leak', 'Origin: Leak', 'Origin: Shower Plumbing',
            'Origin: Service Line', 'Origin: Sewer Line', 'Origin: Sewage Line/Pipe',
            'Origin: Sump Pump', 'Origin: Water (Unknown)', 'Origin: Gas Leak',
            'Origin: A/C', 'Origin: Septic Tank', 'Origin: Boiler', 'Origin: Heater',
            'Origin: Washing Machine', 'Origin: Stove Top', 'Origin: Dishwasher',
            'Origin: Dryer', 'Origin: Refrigerator', 'Origin: Oven', 'Origin: Water Heater',
            'Origin: Mold', 'Origin: Window', 'Origin: Computer', 'Origin: Exterior Home',
            'Origin: Vehicle Hit', 'Origin: Pool Equipment', 'Origin: Pool Pipe/Leak',
            'Origin: Bathtub', 'Origin: Shower', 'Origin: Shower', 'Origin: Toilet',
            'Origin: Sink', 'Origin: Water Faucet', 'Origin: Clogged Drain',
            'Origin: Drain', 'Origin: Theft', 'Origin: Jewelry Lost', 'Origin: Ice Maker',
            'Origin: Microwave', 'Origin: Slab Leak', 'Origin: Foundation Issues',
            'Origin: Dog', 'Origin: Driver Hit Fence', 'Origin: Fence'
        };
        for (Case c : cases) {
            String text = c.Loss_Description__c + '. ' + c.Damage_Description__c;
            List<String> tags = client.analyze(text);
            for (String location : locations) {
                if (tags.contains(location)) {
                    system.debug('Has location: ' + location + '!');
                    c.Location__c = location;
                    break;
                }
            }
            for (String cause : causes) {
                if (tags.contains(cause)) {
                    system.debug('Has cause: ' + cause + '!');
                    c.Cause__c = cause;
                    break;
                }
            }
            for (String origin : origins) {
                if (tags.contains(origin)) {
                    system.debug('Has origin: ' + origin + '!');
                    c.Origin__c = origin;
                    break;
                }
            }
        }
        update cases;
    }

}*/